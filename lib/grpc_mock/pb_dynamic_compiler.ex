defmodule GrpcMock.PbDynamicCompiler do
  use GenServer
  require Logger

  @out_dir Application.compile_env(:grpc_mock, :proto_out_dir)

  ##############
  ## client apis
  ##############

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  def protoc_codegen(import_path, proto_files_glob) do
    GenServer.cast(__MODULE__, {:protoc_codegen, import_path, proto_files_glob})
  end

  def load_modules do
    GenServer.cast(__MODULE__, {:load_module})
  end

  def modules_available do
    GenServer.call(__MODULE__, {:modules_available})
  end

  ##############
  ## server apis
  ##############
  def init(modules) do
    Logger.info("starting dynamic proto compiler")
    {:ok, modules}
  end

  def handle_cast({:protoc_codegen, import_path, proto_files_glob}, modules) do
    {_, 0} =
      System.cmd(
        "protoc",
        ~w(--proto_path=#{import_path} --elixir_opt=package_prefix=GprcMock.Protos --elixir_out=plugins=grpc:#{@out_dir} #{proto_files_glob})
      )

    {:noreply, modules}
  end

  def handle_cast({:load_module}, modules) do
    Logger.info("loading compiled modules")

    compiled_modules =
      "#{@out_dir}/**/*.ex"
      |> Path.wildcard()
      |> Enum.map(&Code.compile_file/1)
      |> List.flatten()
      |> Keyword.keys()
      |> MapSet.new()

    Logger.info("loading of modules is successful")

    {:noreply, MapSet.union(compiled_modules, modules)}
  end

  def handle_call({:modules_available}, _from, modules) do
    {:reply, modules, modules}
  end
end
