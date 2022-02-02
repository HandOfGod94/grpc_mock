defmodule GrpcMock.DynamicServer do
  import GrpcMock.DynamicServer.Servergen

  alias Registry
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicSupervisor
  alias GrpcMock.DynamicServer.Servergen
  alias GrpcMock.DynamicServer.Servergen.ServerRepo

  require Logger

  defmodule StartFailedError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to start server. reason: #{inspect(reason)}"
  end

  @registry GrpcMock.ServerRegistry

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

  def start_server(servergen, server_params) do
    servergen =
      servergen
      |> build_server_struct(server_params)
      |> generate_implmentation()
      |> start(nodes: [node() | Node.list()])
      |> save(ServerRepo)
      |> apply_instruction()

    cond do
      servergen.valid? -> {:ok, servergen.server}
      Servergen.changeset_error(servergen) != nil -> {:error, Servergen.changeset_error(servergen)}
      true -> {:error, %StartFailedError{reason: servergen.errors}}
    end
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

    Enum.each(nodes, fn node ->
      Node.spawn(node, fn ->
        owner_node_pid = :pg.get_local_members(id) |> Enum.at(0)
        DynamicSupervisor.stop_server(owner_node_pid)
      end)
    end)
  end
end
