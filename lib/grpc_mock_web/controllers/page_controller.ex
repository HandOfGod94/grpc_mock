defmodule GrpcMockWeb.PageController do
  use GrpcMockWeb, :controller
  require Logger

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, %{"import_path" => import_path, "proto_file_glob" => proto_file_glob}) do
    Logger.info("Import path: #{import_path}")
    Logger.info("Proto File Glob: #{proto_file_glob}")
    render(conn, "index.html")
  end
end
