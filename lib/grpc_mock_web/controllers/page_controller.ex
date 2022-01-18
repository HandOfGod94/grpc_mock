defmodule GrpcMockWeb.PageController do
  use GrpcMockWeb, :controller
  require Logger
  alias GrpcMock.PbDynamicCompiler

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, %{"import_path" => import_path, "proto_file_glob" => proto_file_glob}) do
    PbDynamicCompiler.protoc_compile(import_path, proto_file_glob)
    PbDynamicCompiler.load_modules()
    render(conn, "index.html")
  end
end
