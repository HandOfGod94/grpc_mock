defmodule GrpcMockWeb.DynamicServerController do
  use GrpcMockWeb, :controller

  alias GrpcMock.DynamicGrpc

  def index(conn, _params) do
    dynamic_servers = DynamicGrpc.list_all_servers()
    render(conn, "index.html", dynamic_servers: dynamic_servers)
  end

  def show(conn, %{"id" => id}) do
    {pid, server} = DynamicGrpc.fetch_server(id)
    render(conn, "show.html", pid: pid, dynamic_server: server)
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _dynamic_server} = DynamicGrpc.stop_server(id)

    conn
    |> put_flash(:info, "Dynamic server stopped successfully.")
    |> redirect(to: Routes.dynamic_server_path(conn, :index))
  end
end
