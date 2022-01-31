defmodule GrpcMockWeb.ProtocModuleLive.Index do
  use GrpcMockWeb, :live_view
  require Logger
  alias GrpcMock.DynamicCompiler
  alias Phoenix.PubSub

  @pubsub GrpcMock.PubSub
  @compile_status_topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)

  @messages %{
    in_progress: "Compilation in progress",
    done: "Successfully compiled and loaded all the modules",
    failed: "Failed to load protoc module"
  }

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(@pubsub, @compile_status_topic)
    {:ok, assign(socket, protoc_modules: list_protoc_modules())}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"protoc_compiler" => params}, socket) do
    %{"import_path" => import_path, "proto_file_glob" => proto_file_glob} = params
    DynamicCompiler.load_for_proto(import_path, proto_file_glob)

    {:noreply,
     socket
     |> put_flash(:info, @messages[:in_progress])
     |> assign(:protoc_modules, list_protoc_modules())}
  end

  @impl Phoenix.LiveView
  def handle_info(%{status: :failed, reason: reason}, socket) do
    message = "#{@messages[:failed]}, Reason: #{inspect(reason)}"
    socket = socket |> put_flash(:error, message)
    {:noreply, assign(socket, protoc_modules: list_protoc_modules())}
  end

  def handle_info(%{status: status}, socket) do
    socket = put_flash(socket, :info, @messages[status])
    {:noreply, assign(socket, :protoc_modules, list_protoc_modules())}
  end

  def handle_info(message, socket) do
    Logger.warning("unknown message recieved. #{inspect(message)}")
    {:noreply, socket}
  end

  defp list_protoc_modules, do: DynamicCompiler.available_modules()
end
