defmodule GrpcMock.DynamicGrpc.DynamicSupervisor do
  use DynamicSupervisor
  alias GrpcMock.DynamicGrpc.Server
  alias GrpcMock.DynamicGrpc.GrpcGenServer

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_server(Server.t(), atom()) :: DynamicSupervisor.on_start_child()
  def start_server(server, endpoint) do
    spec = {GrpcGenServer, {server, endpoint}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @spec stop_server(pid()) :: :ok | {:error, :not_found}
  def stop_server(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
