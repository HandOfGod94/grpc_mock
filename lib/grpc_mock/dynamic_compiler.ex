defmodule GrpcMock.DynamicCompiler do
  require Logger
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo

  @task_supervisor GrpcMock.TaskSupervisor

  @spec load_for_proto(String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def load_for_proto(import_path, proto_file) do
    Task.Supervisor.start_child(@task_supervisor, ProtocLoader, :load_modules, [import_path, proto_file])
  end

  @spec available_modules :: list(atom())
  def available_modules do
    ModuleRepo.all_dirty()
  end
end
