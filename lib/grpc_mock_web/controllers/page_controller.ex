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
    case PbDynamicCompiler.codegen(import_path, proto_file_glob) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Successfully loaded modules")
        |> render("index.html", protoc_modules: available_modules())

      {:error, errors} ->
        conn
        |> put_flash(:error, Exception.message(errors))
        |> render("index.html", protoc_modules: available_modules())
    end
  end
end
