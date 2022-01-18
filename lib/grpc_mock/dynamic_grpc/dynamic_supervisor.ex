defmodule GrpcMock.DynamicGrpc.DynamicSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
