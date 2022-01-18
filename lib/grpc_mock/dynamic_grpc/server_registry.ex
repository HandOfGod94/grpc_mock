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
      {:error, errors} -> {:error, errors}
    end
  end

  def fetch_server(id) do
    Agent.get(__MODULE__, fn servers ->
      Enum.find_value(servers, fn server -> server.id == id end)
    end)
  end

  def update_server(id, params) do
    Agent.update(__MODULE__, fn servers ->
      with idx when idx >= 0 <- Enum.find_index(servers, fn server -> server.id == id end),
           server <- Enum.at(servers, idx),
           {:ok, server} <- Server.update(server, params) do
        List.replace_at(servers, idx, server)
      else
        _ -> servers
      end
    end)
  end

  def start_dynamic_server(id) do
    Agent.get_and_update(__MODULE__, fn servers ->
      with server when server != nil <- fetch_server(id),
           [_, {endpoint, _}] <- DynamicGrpc.generate_implmentation(server),
           {:ok, pid} <-
             DynamicSupervisor.start_child({GRPC.Server.Supervisor, {endpoint, 50001}}) do
        {server, update_server(id, %{status: "up", pid: to_string(pid)})}
      else
        _ -> {servers, servers}
      end
    end)
  end

  def stop_dynamic_server(id) do
    Agent.get_and_update(__MODULE__, fn servers ->
      with server when server != nil <- fetch_server(id),
           :ok <- GenServer.stop(pid(server.pid)),
           {:ok, server} <- Server.update(server, %{status: "down", pid: nil}) do
        updated_server_list = List.replace_at(servers, idx, server)
        {servers, update_server(id, %{status: "down", pid: nil})}
      else
        _ -> {servers, servers}
      end
    end)
  end
end
