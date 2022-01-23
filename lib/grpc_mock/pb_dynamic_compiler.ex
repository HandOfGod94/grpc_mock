defmodule GrpcMock.PbDynamicCompiler do
  require Logger

  import GrpcMock.PbDynamicCompiler.ModuleStore

  alias Phoenix.PubSub
  alias GrpcMock.PbDynamicCompiler.CompileStatus

  @compile_status_topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)
  @pubsub GrpcMock.PubSub
  @task_supervisor GrpcMock.TaskSupervisor

  defmodule CodegenError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  @spec codegen(binary(), binary()) :: DynamicSupervisor.on_start_child()
  def codegen(import_path, proto_files_glob) do
    Task.Supervisor.start_child(@task_supervisor, fn ->
      with :ok <- protoc(import_path, proto_files_glob),
           {:ok, mods} <- load_modules() do
        save_modules(mods)
        PubSub.broadcast!(@pubsub, @compile_status_topic, %CompileStatus{status: :finished})
        Logger.info("loading of modules was successful")
      else
        {:error, %CodegenError{} = error} ->
          Logger.error(Exception.message(error))

          PubSub.broadcast!(@pubsub, @compile_status_topic, %CompileStatus{
            error: error,
            status: :failed
          })
      end
    end)
  end

  @spec available_modules :: MapSet.t()
  def available_modules do
    {:atomic, list_of_modules} = :mnesia.transaction(fn -> :mnesia.all_keys(:module) end)
    list_of_modules
  end

  defp load_modules do
    Logger.info("loading compiled modules")

    try do
      compiled_modules =
        "#{proto_out_dir!()}/**/*.ex"
        |> Path.wildcard()
        |> Enum.map(&Code.compile_file/1)
        |> List.flatten()
        |> Keyword.keys()
        |> MapSet.new()

      {:ok, compiled_modules}
    catch
      error -> {:error, %CodegenError{reason: error}}
    end
  end

  defp save_modules(modules) do
    :mnesia.transaction(fn ->
      Enum.each(modules, fn module ->
        record = module(id: module, name: module)
        :mnesia.write(record)
      end)
    end)
  end

  defp protoc(import_path, proto_files_glob) do
    System.cmd(
      "protoc",
      ~w(--proto_path=#{import_path} --elixir_opt=package_prefix=GprcMock.Protos --elixir_out=plugins=grpc:#{proto_out_dir!()} #{proto_files_glob}),
      stderr_to_stdout: true
    )
    |> case do
      {_, 0} -> :ok
      {msg, _} -> {:error, %CodegenError{reason: msg}}
    end
  end

  defp proto_out_dir! do
    Application.fetch_env!(:grpc_mock, :proto_out_dir)
  end
end
