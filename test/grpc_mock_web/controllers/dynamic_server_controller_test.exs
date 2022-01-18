defmodule GrpcMockWeb.DynamicServerControllerTest do
  use GrpcMockWeb.ConnCase

  import GrpcMock.DynamicGrpcFixtures

  @create_attrs %{mock_responses: %{}, port: 42, service: "some service"}
  @update_attrs %{mock_responses: %{}, port: 43, service: "some updated service"}
  @invalid_attrs %{mock_responses: nil, port: nil, service: nil}

  describe "index" do
    test "lists all dynamic_servers", %{conn: conn} do
      conn = get(conn, Routes.dynamic_server_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Dynamic servers"
    end
  end

  describe "new dynamic_server" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.dynamic_server_path(conn, :new))
      assert html_response(conn, 200) =~ "New Dynamic server"
    end
  end

  describe "create dynamic_server" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.dynamic_server_path(conn, :create), dynamic_server: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.dynamic_server_path(conn, :show, id)

      conn = get(conn, Routes.dynamic_server_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Dynamic server"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.dynamic_server_path(conn, :create), dynamic_server: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Dynamic server"
    end
  end

  describe "edit dynamic_server" do
    setup [:create_dynamic_server]

    test "renders form for editing chosen dynamic_server", %{conn: conn, dynamic_server: dynamic_server} do
      conn = get(conn, Routes.dynamic_server_path(conn, :edit, dynamic_server))
      assert html_response(conn, 200) =~ "Edit Dynamic server"
    end
  end

  describe "update dynamic_server" do
    setup [:create_dynamic_server]

    test "redirects when data is valid", %{conn: conn, dynamic_server: dynamic_server} do
      conn = put(conn, Routes.dynamic_server_path(conn, :update, dynamic_server), dynamic_server: @update_attrs)
      assert redirected_to(conn) == Routes.dynamic_server_path(conn, :show, dynamic_server)

      conn = get(conn, Routes.dynamic_server_path(conn, :show, dynamic_server))
      assert html_response(conn, 200) =~ "some updated service"
    end

    test "renders errors when data is invalid", %{conn: conn, dynamic_server: dynamic_server} do
      conn = put(conn, Routes.dynamic_server_path(conn, :update, dynamic_server), dynamic_server: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Dynamic server"
    end
  end

  describe "delete dynamic_server" do
    setup [:create_dynamic_server]

    test "deletes chosen dynamic_server", %{conn: conn, dynamic_server: dynamic_server} do
      conn = delete(conn, Routes.dynamic_server_path(conn, :delete, dynamic_server))
      assert redirected_to(conn) == Routes.dynamic_server_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.dynamic_server_path(conn, :show, dynamic_server))
      end
    end
  end

  defp create_dynamic_server(_) do
    dynamic_server = dynamic_server_fixture()
    %{dynamic_server: dynamic_server}
  end
end
