defmodule GrpcMock.DynamicCompiler do
  require Logger
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicCompiler.Codegen.ModulesRepo

  @task_supervisor GrpcMock.TaskSupervisor

  @spec load_for_proto(String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def load_for_proto(import_path, proto_file) do
    Task.Supervisor.start_child(@task_supervisor, ProtocLoader, :load_modules, [import_path, proto_file])
  end

  @spec load_for_proto_sync(String.t(), String.t()) :: {:ok, term()} | {:error, any()}
  def load_for_proto_sync(import_path, proto_file) do
    ProtocLoader.load_modules(import_path, proto_file)
  end

  @spec available_modules :: list(atom())
  def available_modules, do: ModulesRepo.all_dirty()
end
