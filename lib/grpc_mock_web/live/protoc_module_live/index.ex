defmodule GrpcMockWeb.ProtocModuleLive.Index do
  use GrpcMockWeb, :live_view

  alias GrpcMock.PbDynamicCompiler

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :protoc_modules, list_protoc_modules())}
  end

  defp list_protoc_modules do
    PbDynamicCompiler.modules_available()
  end
end
