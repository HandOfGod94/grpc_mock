defmodule GrpcMock.PbDynamicCompiler do
  require Logger
  alias GrpcMock.Codegen.ProtoLoader
  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo

  @task_supervisor GrpcMock.TaskSupervisor

  @spec codegen(binary(), binary()) :: DynamicSupervisor.on_start_child()
  def codegen(import_path, proto_files_glob) do
    Task.Supervisor.start_child(@task_supervisor, ProtoLoader, :load_modules, [import_path, proto_files_glob])
  end

  @spec available_modules :: list(atom())
  def available_modules do
    ModuleRepo.all_dirty()
  end
end
