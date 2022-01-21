defmodule GrpcMock.PbDynamicCompiler do
  use GenServer
  require Logger

  @out_dir Application.compile_env(:grpc_mock, :proto_out_dir)

  defmodule CodegenError do
    defexception [:reason]
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  ##############
  ## client apis
  ##############

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  def codegen(import_path, proto_files_glob) do
    GenServer.cast(__MODULE__, {:codegen, import_path, proto_files_glob})
  end

  def available_modules do
    GenServer.call(__MODULE__, {:available_modules})
  end

  ##############
  ## server apis
  ##############
  def init(modules) do
    Logger.info("starting dynamic proto compiler")
    {:ok, modules}
  end

  def handle_cast({:codegen, import_path, proto_files_glob}, modules) do
    with :ok <- protoc(import_path, proto_files_glob),
         {:ok, mods} <- load_modules() do
      Logger.info("loading of modules was successful")
      {:noreply, MapSet.union(mods, modules)}
    else
      _ -> {:noreply, modules}
    end
  end

  def handle_call({:available_modules}, _from, modules) do
    {:reply, modules, modules}
  end

  defp load_modules do
    Logger.info("loading compiled modules")

    try do
      compiled_modules =
        "#{@out_dir}/**/*.ex"
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
      ~w(--proto_path=#{import_path} --elixir_opt=package_prefix=GprcMock.Protos --elixir_out=plugins=grpc:#{@out_dir} #{proto_files_glob})
    )
    |> case do
      {_, 0} -> :ok
      {msg, _} -> {:error, %CodegenError{reason: msg}}
    end
  end
end
