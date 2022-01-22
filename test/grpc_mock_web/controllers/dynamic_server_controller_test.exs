defmodule GrpcMockWeb.DynamicServerControllerTest do
  use GrpcMockWeb.ConnCase
  import GrpcMock.Factory
  alias GrpcMock.DynamicGrpc
  alias GrpcMock.PbDynamicCompiler

  @registry GrpcMock.ServerRegistry

  describe "index" do
    test "lists all dynamic_servers", %{conn: conn} do
      conn = get(conn, Routes.dynamic_server_path(conn, :index))
      assert html_response(conn, 200) =~ "GRPC Servers"
    end
  end

  describe "show" do
    setup [:create_dynamic_server]

    test "show dynamic server details when server is present",
         %{conn: conn, dynamic_server: dynamic_server} do
      conn = get(conn, Routes.dynamic_server_path(conn, :show, dynamic_server))
      resp = html_response(conn, 200)
      assert resp =~ "Dynamic Server Details"
      assert resp =~ dynamic_server.service
      assert resp =~ "#{dynamic_server.port}"
    end

    test "render 404 when server is absent",
         %{conn: conn, dynamic_server: dynamic_server} do
      invalid_server = %{dynamic_server | id: "foobar"}
      conn = get(conn, Routes.dynamic_server_path(conn, :show, invalid_server))
      assert redirected_to(conn) == Routes.dynamic_server_path(conn, :index)
      assert get_flash(conn, :error) == "Server not found"
    end
  end

  describe "stop dynamic_server" do
    setup [:start_pb_dynamic_compiler, :create_dynamic_server]

    test "stop and delete chosen dynamic_server", %{conn: conn} do
      server = build(:server, id: "start-wars-#{Nanoid.generate()}")
      {:ok, _} = DynamicGrpc.start_server(server)

      conn = delete(conn, Routes.dynamic_server_path(conn, :delete, server))
      assert redirected_to(conn) == Routes.dynamic_server_path(conn, :index)
      assert get_flash(conn, :info) == "Dynamic server stopped successfully."
    end
  end

  defp start_pb_dynamic_compiler(_) do
    start_supervised(PbDynamicCompiler)

    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    PbDynamicCompiler.codegen(import_path, "helloworld.proto")
    # wait till cast request completes
    :sys.get_state(PbDynamicCompiler)

    :ok
  end

  defp create_dynamic_server(_) do
    server = build(:server)

    # register with process
    name = {:via, Registry, {@registry, server.id, server}}
    {:ok, _} = Agent.start_link(fn -> %{} end, name: name)

    %{dynamic_server: server}
  end
end
