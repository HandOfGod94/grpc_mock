defmodule GrpcMock.DynamicCompiler do
  require Logger
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicCompiler.Codegen.ModulesRepo

  @task_supervisor GrpcMock.TaskSupervisor

  @spec load_proto_types(String.t(), String.t()) :: {:ok, term()} | {:error, any()}
  defdelegate load_proto_types(import_path, proto_file), to: ProtocLoader, as: :load_modules

  @spec async_load_proto_types(String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def async_load_proto_types(import_path, proto_file) do
    Task.Supervisor.start_child(@task_supervisor, fn -> load_proto_types(import_path, proto_file) end)
  end

  @spec available_modules :: list(atom())
  def available_modules, do: ModulesRepo.all_dirty()
end
