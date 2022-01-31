defmodule GrpcMock.DynamicCompiler.ProtocCodegen do
  use GrpcMock.Codegen

  require Logger
  import GrpcMock.Codegen
  alias GrpcMock.Codegen.Instruction
  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo

  @type t :: %__MODULE__{import_path: String.t(), file: String.t()}
  defstruct [:import_path, :file]

  defmodule CodeLoadError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  @spec compile(String.t(), String.t()) :: {t(), [Instruction.dynamic_module()]}
  def compile(import_path, file) do
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

    protoc(import_path, file)
    |> then(fn :ok -> do_load_modules() end)
    |> then(fn {:ok, compiled} -> compiled end)
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

    try do
      compiled =
        "#{proto_out_dir!()}/**/*.ex"
        |> Path.wildcard()
        |> Enum.map(&Code.compile_file/1)
        |> List.flatten()

      Logger.info("Proto generated modules are successfully loaded.")
      {:ok, compiled}
    catch
      error -> {:error, %CodeLoadError{reason: error}}
    end
  end

  defp proto_out_dir!, do: Application.fetch_env!(:grpc_mock, :proto_out_dir)
end
