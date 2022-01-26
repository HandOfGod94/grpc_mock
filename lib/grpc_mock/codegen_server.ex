defmodule GrpcMock.CodegenServer do
  use GenServer
  require Logger
  alias GrpcMock.Codegen.DbLoader
  alias GrpcMock.Codegen.EExLoader
  alias GrpcMock.Codegen.ProtoLoader

  @task_sup GrpcMock.TaskSupervisor

  ###############
  ### Client APIs
  ###############

  def start_link(init_args, _opts \\ []) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def codegen(instruction) do
    GenServer.cast(__MODULE__, {:codegen, instruction})
  end

  ###############
  ### Server APIs
  ###############

  def init({:codegen, _} = args) do
    {:ok, [], {:continue, args}}
  end

  def init(_args) do
    {:ok, []}
  end

  def handle_continue({:codegen, instruction}, state) do
    {mod, fun, args} = decode_instruction(instruction)
    apply(mod, fun, args)
    {:noreply, state ++ [instruction]}
  end

  def handle_cast({:codegen, instruction}, state) do
    {mod, fun, args} = decode_instruction(instruction)

    @task_sup
    |> Task.Supervisor.async_nolink(mod, fun, args)
    |> Task.yield()
    |> case do
      {:ok, _} ->
        {:noreply, state ++ [instruction]}

      error ->
        Logger.error("Failed to generate code. Reason: #{inspect(error)}")
        {:noreply, state}
    end
  end

  def decode_instruction(instruction) do
    case instruction do
      :load_from_db -> {DbLoader, :load_modules, []}
      {:eex, [template: template, bindings: bindings]} -> {EExLoader, :load_modules, [template, bindings]}
      {:protoc, [import_path: path, proto_file: file]} -> {ProtoLoader, :load_modules, [path, file]}
    end
  end
end
