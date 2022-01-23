defmodule GrpcMockWeb.ProtocModuleLive.Index do
  use GrpcMockWeb, :live_view

  alias GrpcMock.PbDynamicCompiler
  alias GrpcMock.PbDynamicCompiler.CompileStatus
  alias Phoenix.PubSub

  @pubsub GrpcMock.PubSub
  @compile_status_topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(@pubsub, @compile_status_topic)
    {:ok, assign(socket, protoc_modules: list_protoc_modules())}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"protoc_compiler" => params}, socket) do
    %{"import_path" => import_path, "proto_file_glob" => proto_file_glob} = params
    PbDynamicCompiler.codegen(import_path, proto_file_glob)

    {:noreply,
     socket
     |> put_flash(:info, "Compilation in progress")
     |> assign(:protoc_modules, list_protoc_modules())}
  end

  @impl Phoenix.LiveView
  def handle_info(%CompileStatus{} = message, socket) do
    case message do
      %{status: :failed} ->
        socket = put_flash(socket, :error, format_compile_status(message))
        {:noreply, assign(socket, protoc_modules: list_protoc_modules())}

      otherwise ->
        socket = put_flash(socket, :info, format_compile_status(otherwise))
        {:noreply, assign(socket, :protoc_modules, list_protoc_modules())}
    end
  end

  defp list_protoc_modules do
    PbDynamicCompiler.available_modules()
  end

  defp format_compile_status(%CompileStatus{} = status) do
    case status do
      %{status: :finished} ->
        "Successfully compiled and loaded all the modules"

      %{status: :failed, error: error} ->
        "Failed to load protoc module. error: #{Exception.message(error)}"
    end
  end
end
