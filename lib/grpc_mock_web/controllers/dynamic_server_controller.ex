defmodule GrpcMockWeb.DynamicServerController do
  use GrpcMockWeb, :controller

  alias GrpcMock.DynamicGrpc

  def index(conn, _params) do
    dynamic_servers = DynamicGrpc.list_all_servers()
    render(conn, "index.html", dynamic_servers: dynamic_servers)
  end

  def show(conn, %{"id" => id}) do
    case DynamicGrpc.fetch_server(id) do
      {pid, server} ->
        render(conn, "show.html", pid: pid, dynamic_server: server)

      _ ->
        conn
        |> put_flash(:error, "Server not found")
        |> redirect(to: Routes.dynamic_server_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id}) do
    case DynamicGrpc.stop_server(id) do
      {:ok, _dynamic_server} ->
        conn
        |> put_flash(:info, "Dynamic server stopped successfully.")
        |> redirect(to: Routes.dynamic_server_path(conn, :index))

      {:error, error} ->
        conn
        |> put_flash(:error, "Error while stopping server. Reason: #{inspect error}")
        |> redirect(to: Routes.dynamic_server_path(conn, :index))
    end
  end
end
