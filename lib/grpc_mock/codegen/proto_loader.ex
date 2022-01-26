defmodule GrpcMock.Codegen.ProtoLoader do
  require Logger

  import GrpcMock.Codegen.Modules.Store

  alias GrpcMock.Extension.Code, as: ExtCode
  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo

  defmodule CodeLoadError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  def load_modules(import_path, proto_file) do
    with :ok <- protoc(import_path, proto_file),
         {:ok, compiled} <- do_load_modules(),
         :ok <- publish(compiled),
         {:atomic, _} <- save_to_db(compiled) do
      Logger.info("successfully saved compiled code to DB")
    end
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

  defp publish(modules) do
    Enum.each(modules, fn {module_name, module_code} ->
      ExtCode.remote_load(module_name, module_code)
    end)

    Logger.info("Published to all nodes")
  end

  defp save_to_db(modules) do
    modules
    |> Enum.map(fn {module_name, module_code} ->
      dyn_module(
        id: module_name,
        name: module_name,
        filename: ExtCode.dynamic_module_filename(module_name),
        code_binary: module_code
      )
    end)
    |> ModuleRepo.save_all()
  end

  defp proto_out_dir!, do: Application.fetch_env!(:grpc_mock, :proto_out_dir)
end
