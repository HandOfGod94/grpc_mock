defmodule GrpcMock.DynamicGrpc.ServerRegistry do
  use Agent
  require Logger
  alias GrpcMock.DynamicGrpc.Server
  alias GrpcMock.DynamicGrpc
  alias GrpcMock.DynamicGrpc.DynamicSupervisor

  def start_link(_opts) do
    Logger.info("starting dynamic server registry")
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def list_servers() do
    Agent.get(__MODULE__, &Function.identity/1)
  end

  def create_dynamic_server(params) do
    case Server.new(params) do
      {:ok, server} -> Agent.update(__MODULE__, fn servers -> [server | servers] end)
      {:error, error} -> {:error, error}
    end
  end

  def start_dynamic_server(server) do
    Agent.get_and_update(__MODULE__, fn servers ->
      with idx when idx >= 0 <- Enum.find_index(servers, fn s -> s == server end),
           [_, endpoint_mod] <- DynamicGrpc.generate_implmentation(server.service, server.mocks),
           endpoint <- elem(endpoint_mod, 0),
           {:ok, pid} <-
             DynamicSupervisor.start_child({GRPC.Server.Supervisor, {endpoint, 50001}}) do
        updated_server_list =
          List.update_at(servers, idx, fn server -> %{server | status: :up, pid: pid} end)

        {servers, updated_server_list}
      else
        _ -> {servers, servers}
      end
    end)
  end

  def stop_dynamic_server(server) do
    Agent.get_and_update(__MODULE__, fn servers ->
      with idx when idx >= 0 <- Enum.find_index(servers, fn s -> s == server end),
           server <- Enum.at(servers, idx),
           :ok <- GenServer.stop(server.pid) do
        updated_server_list =
          List.update_at(servers, idx, fn server -> %{server | status: :down, pid: nil} end)

        {servers, updated_server_list}
      else
        _ -> {servers, servers}
      end
    end)
  end
end
