defmodule GrpcMock.PbDynamicCompiler do
  use GenServer
  require Logger
  alias Phoenix.PubSub
  alias GrpcMock.PbDynamicCompiler.CompileStatus

  @compile_status_topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)
  @pubsub GrpcMock.PubSub

  defmodule CodegenError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  ##############
  ## client apis
  ##############

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  @spec codegen(binary(), binary()) :: :ok
  def codegen(import_path, proto_files_glob) do
    GenServer.cast(__MODULE__, {:codegen, import_path, proto_files_glob})
  end

  @spec available_modules :: MapSet.t()
  def available_modules do
    GenServer.call(__MODULE__, {:available_modules})
  end

  ##############
  ## server apis
  ##############
  @impl GenServer
  def init(modules) do
    Logger.info("starting dynamic proto compiler")
    {:ok, modules}
  end

  @impl GenServer
  def handle_cast({:codegen, import_path, proto_files_glob}, modules) do
    with :ok <- protoc(import_path, proto_files_glob),
         {:ok, mods} <- load_modules() do
      Logger.info("loading of modules was successful")
      PubSub.broadcast!(@pubsub, @compile_status_topic, %CompileStatus{status: :finished})
      {:noreply, MapSet.union(mods, modules)}
    else
      {:error, %CodegenError{} = error} ->
        Logger.error(Exception.message(error))

        PubSub.broadcast!(@pubsub, @compile_status_topic, %CompileStatus{
          error: error,
          status: :failed
        })

        {:noreply, modules}
    end
  end

  @impl GenServer
  def handle_call({:available_modules}, _from, modules) do
    {:reply, modules, modules}
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
