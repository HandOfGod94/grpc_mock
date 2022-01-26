defmodule GrpcMock.DynamicGrpc do
  alias Horde.Registry
  alias GrpcMock.DynamicGrpc.Server
  alias GrpcMock.DynamicGrpc.DynamicSupervisor
  alias GrpcMock.PbDynamicCompiler.CodeLoad
  alias GrpcMock.CodegenServer

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
    with [_, {endpoint, _}] <- generate_implmentation(server),
         {:ok, _} <- Swarm.register_name(server.id, DynamicSupervisor, :start_server, [server, endpoint]) do
      {:ok, server}
    else
      {:error, %MockgenError{} = error} -> {:error, error}
      {:error, %Ecto.Changeset{} = errors} -> {:error, errors}
      {:error, error} -> {:error, %StartFailedError{reason: error}}
    end
  end

  @spec stop_server(Server.id()) :: {:ok, Server.t()} | {:error, :not_found} | nil
  def stop_server(id) do
    with {pid, server} <- fetch_server(id),
         :ok <- DynamicSupervisor.stop_server(pid) do
      Logger.info("successfully stopped server")
      {:ok, server}
    end
  end

  @spec change_dynamic_server(Server.t(), map()) :: Ecto.Changeset.t()
  def change_dynamic_server(server, params \\ %{}) do
    Server.changeset(server, params)
  end

  defp generate_implmentation(%Server{} = server) do
    try do
      mocks = set_method_body!(server.mock_responses)

      CodegenServer.codegen(
        {:eex,
         template: "dynamic_server.eex",
         bindings: [app: app_name(server.service), service: server.service, mocks: mocks]}
      )
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
