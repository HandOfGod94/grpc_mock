defmodule GrpcMock.DynamicGrpc.DynamicSupervisor do
  use DynamicSupervisor
  alias GrpcMock.DynamicGrpc.GrpcGenServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_server(server, endpoint) do
    spec = {GrpcGenServer, {server, endpoint}}
    DynamicSupervisor.start_child(__MODULE__,spec)
  end

  def stop_server(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
