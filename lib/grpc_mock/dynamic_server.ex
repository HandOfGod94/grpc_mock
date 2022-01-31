defmodule GrpcMock.DynamicServer do
  alias Registry
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicSupervisor
  alias GrpcMock.DynamicCompiler.EExCodeGen

  require Logger

  defmodule StartFailedError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to start server. reason: #{inspect(reason)}"
  end

  defmodule MockgenError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to create mock. reason: #{inspect(reason)}"
  end

  @registry GrpcMock.ServerRegistry
  @otp_app :grpc_mock

  @moduledoc """
  format in which servers are stored in registry:
  {key, pid, serverstrucct} where key == Nanoid
  """

  @spec list_all_servers() :: list(Server.t())
  def list_all_servers do
    match_pattern = {:_, :"$1", :"$2"}
    guards = []
    body = [%{pid: :"$1", server: :"$2"}]

    queryspec = [{match_pattern, guards, body}]
    Registry.select(@registry, queryspec)
  end

  @spec fetch_server(Server.id()) :: {pid(), Server.t()} | nil
  def fetch_server(id) do
    case Registry.lookup(@registry, id) do
      [{pid, value}] -> {pid, value}
      _ -> nil
    end
  end

  @spec start_server(Server.t()) :: {:ok, Server.t()} | {:error, any()}
  def start_server(%Server{} = server) do
    with [_, {endpoint, _, _}] <- generate_implmentation(server),
         :ok <- start_grpc_server(server, endpoint, Node.list()) do
      {:ok, server}
    else
      {:error, %MockgenError{} = error} -> {:error, error}
      {:error, %Ecto.Changeset{} = errors} -> {:error, errors}
      {:error, error} -> {:error, %StartFailedError{reason: error}}
    end
  end

  def start_grpc_server(server, endpoint, nodes) do
    nodes = [node() | nodes]

    nodes
    |> Enum.with_index()
    |> Enum.each(fn {node, idx} ->
      ## HACK: for now it's just incrementing port number, so in local it doesn't clash
      server = %{server | port: server.port + idx}

      Node.spawn(node, fn ->
        {:ok, pid} = DynamicSupervisor.start_server(server, endpoint)
        :pg.join(server.id, pid)
      end)
    end)
  end

  @spec stop_server(Server.id()) :: {:ok, Server.t()} | {:error, :not_found} | nil
  def stop_server(id) do
    with {_pid, server} <- fetch_server(id),
         :ok <- stop_on_all_nodes(id) do
      Logger.info("successfully stopped server")
      {:ok, server}
    end
  end

  defp stop_on_all_nodes(id) do
    nodes = [node() | Node.list()]

    nodes
    |> Enum.each(fn node ->
      Node.spawn(node, fn ->
        owner_node_pid = :pg.get_local_members(id) |> Enum.at(0)
        DynamicSupervisor.stop_server(owner_node_pid)
      end)
    end)
  end

  defp generate_implmentation(%Server{} = server) do
    try do
      mocks = set_method_body!(server.mock_responses)
      template = :code.priv_dir(@otp_app) |> Path.join("dynamic_server.eex")
      bindings = [app: app_name(server.service), service: server.service, mocks: mocks]

      {_, modules} = EExCodeGen.compile(template, bindings)
      modules
    rescue
      error -> {:error, %MockgenError{reason: error}}
    end
  end

  defp app_name(service_module) do
    service_module
    |> String.split(".")
    |> Enum.at(-2)
  end

  defp set_method_body!(mock_responses) do
    Enum.reduce(mock_responses, [], fn resp, acc ->
      data = Jason.decode!(resp.data, keys: :atoms)
      stub = {resp.method, resp.return_type, inspect(data)}
      [stub | acc]
    end)
  end
end
