defmodule GrpcMockWeb.DynamicServerController do
  use GrpcMockWeb, :controller

  alias GrpcMock.DynamicGrpc
  alias GrpcMock.DynamicGrpc.Server

  def index(conn, _params) do
    dynamic_servers = DynamicGrpc.list_all_servers()
    render(conn, "index.html", dynamic_servers: dynamic_servers)
  end

  def new(conn, _params) do
    changeset = DynamicGrpc.change_dynamic_server(%Server{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"server" => dynamic_server_params}) do
    with {:ok, server} <- Server.new(dynamic_server_params),
         {:ok, server} <- DynamicGrpc.start_server(server) do
      conn
      |> put_flash(:info, "Dynamic server created successfully.")
      |> redirect(to: Routes.dynamic_server_path(conn, :show, server))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    {_pid, server} = DynamicGrpc.fetch_server(id)
    render(conn, "show.html", dynamic_server: server)
  end

  def delete(conn, %{"id" => id}) do
    {:ok, _dynamic_server} = DynamicGrpc.stop_server(id)

    conn
    |> put_flash(:info, "Dynamic server stopped successfully.")
    |> redirect(to: Routes.dynamic_server_path(conn, :index))
  end
end
