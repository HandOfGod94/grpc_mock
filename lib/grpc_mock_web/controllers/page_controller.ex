defmodule GrpcMockWeb.PageController do
  use GrpcMockWeb, :controller
  require Logger
  alias GrpcMock.PbDynamicCompiler
  import PbDynamicCompiler, only: [available_modules: 0]

  def index(conn, _params) do
    render(conn, "index.html", protoc_modules: available_modules())
  end

  def new(conn, _params) do
    render(conn, "index.html", protoc_modules: available_modules())
  end

  def create(conn, %{"import_path" => import_path, "proto_file_glob" => proto_file_glob}) do
    PbDynamicCompiler.codegen(import_path, proto_file_glob)
    render(conn, "index.html")
  end
end
