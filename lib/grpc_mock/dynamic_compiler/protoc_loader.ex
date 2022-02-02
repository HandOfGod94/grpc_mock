defmodule GrpcMock.DynamicCompiler.ProtocLoader do
  require Logger
  import GrpcMock.DynamicCompiler.Codegen
  alias GrpcMock.DynamicCompiler.Codegen
  alias GrpcMock.DynamicCompiler.Codegen.Modules.Repo, as: ModuleRepo

  @type t :: %__MODULE__{import_path: String.t(), file: String.t()}
  defstruct [:import_path, :file]

  defmodule CodeLoadError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  @spec load_modules(String.t(), String.t()) :: {t(), [Codegen.dynamic_module()]}
  def load_modules(import_path, file) do
    %__MODULE__{import_path: import_path, file: file}
    |> cast()
    |> set_compile_instructions()
    |> apply_instruction()
  end

  @topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)
  defp set_compile_instructions(codegen) do
    codegen
    |> generate_modules_with(&protobuf/1)
    |> save_with(ModuleRepo)
    |> broadcast_status(@topic, %{status: :done})
    |> load_modules_on(nodes: Node.list())
  end

  defp protobuf(codegen) do
    import_path = get_field(codegen, :import_path)
    file = get_field(codegen, :file)

    with :ok <- protoc(import_path, file),
         do: do_load_modules()
  end

  defp protoc(import_path, proto_files_glob) do
    System.cmd(
      "protoc",
      ~w(--proto_path=#{import_path} --elixir_opt=package_prefix=GrpcMock.Protos --elixir_out=plugins=grpc:#{proto_out_dir!()} #{proto_files_glob}),
      stderr_to_stdout: true
    )
    |> case do
      {_, 0} -> :ok
      {msg, _} -> {:error, %CodeLoadError{reason: msg}}
    end
  end

  defp do_load_modules do
    Logger.info("Loading proto generated modules")

    compiled =
      "#{proto_out_dir!()}/**/*.ex"
      |> Path.wildcard()
      |> Enum.map(&Code.compile_file/1)
      |> List.flatten()

    Logger.info("Proto generated modules are successfully loaded.")
    {:ok, compiled}
  end

  defp proto_out_dir!, do: Application.fetch_env!(:grpc_mock, :proto_out_dir)
end
