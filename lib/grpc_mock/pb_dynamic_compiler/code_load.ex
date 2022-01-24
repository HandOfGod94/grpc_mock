defmodule GrpcMock.PbDynamicCompiler.CodeLoad do
  @moduledoc """
  When we compile and load the `.pb.ex`, the loaded code remains with the node which did compilation.
  In cluster setup, we need all the nodes to have the same compiled code, so that server mocks can work correctly.

  This task will publish code to all the nodes.
  """

  require Logger
  import GrpcMock.PbDynamicCompiler.ModuleStore
  alias Phoenix.PubSub
  alias GrpcMock.PbDynamicCompiler.CompileStatus

  defmodule CodeLoadError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to generate code. reason: #{inspect(reason)}"
  end

  @type rpc_call_result :: term() | {:badrpc, term()}

  @pubsub GrpcMock.PubSub
  @compile_status_topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)

  def load_modules_from_proto(import_path, proto_file_glob) do
    with :ok <- protoc(import_path, proto_file_glob),
         {:ok, mods} <- load_modules(),
         {:atomic, _} <- save_modules(mods) do
      PubSub.broadcast!(@pubsub, @compile_status_topic, %CompileStatus{status: :finished})
      Logger.info("loading of modules was successful")
    else
      {:error, %CodeLoadError{} = error} ->
        status = %CompileStatus{error: error, status: :failed}
        PubSub.broadcast!(@pubsub, @compile_status_topic, status)
        Logger.error(Exception.message(error))
        {:error, error}

      {:aborted, reason} ->
        status = %CompileStatus{error: %CodeLoadError{reason: reason}, status: :failed}
        PubSub.broadcast!(@pubsub, @compile_status_topic, status)
        Logger.error("failed to save modules in store. reason: #{inspect(reason)}")
        {:error, %CodeLoadError{reason: reason}}
    end
  end

  @doc """
  Loads dynamically generated module to all the remote node
  """
  @spec remote_load(atom(), charlist() | nil, binary()) :: list(rpc_call_result())
  def remote_load(module_name, module_code) do
    remote_load(module_name, dynamic_module_filename(module_name), module_code)
  end

  def remote_load(module_name, filename, module_code) when is_list(filename) do
    for node <- Node.list() do
      :rpc.call(node, :code, :load_binary, [module_name, filename, module_code])
    end
  end

  defp load_modules do
    Logger.info("loading compiled modules")

    try do
      compiled_modules =
        "#{proto_out_dir!()}/**/*.ex"
        |> Path.wildcard()
        |> Enum.map(&Code.compile_file/1)
        |> List.flatten()

      Enum.each(compiled_modules, fn {module_name, module_code} ->
        remote_load(module_name, dynamic_module_filename(module_name), module_code)
      end)

      {:ok, Keyword.keys(compiled_modules)}
    catch
      error -> {:error, %CodeLoadError{reason: error}}
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
      {msg, _} -> {:error, %CodeLoadError{reason: msg}}
    end
  end

  defp dynamic_module_filename(module) do
    module
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
    |> to_charlist()
  end

  defp proto_out_dir!, do: Application.fetch_env!(:grpc_mock, :proto_out_dir)
end
