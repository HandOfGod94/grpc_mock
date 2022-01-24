defmodule GrpcMock.PbDynamicCompiler do
  require Logger
  alias GrpcMock.PbDynamicCompiler.CodeLoad

  @task_supervisor GrpcMock.TaskSupervisor

  @spec codegen(binary(), binary()) :: DynamicSupervisor.on_start_child()
  def codegen(import_path, proto_files_glob) do
    Task.Supervisor.start_child(@task_supervisor, CodeLoad, :load_modules_from_proto, [import_path, proto_files_glob])
  end

  @spec available_modules :: list(atom())
  def available_modules do
    {:atomic, list_of_modules} = :mnesia.transaction(fn -> :mnesia.all_keys(:module) end)
    list_of_modules
  end
end
