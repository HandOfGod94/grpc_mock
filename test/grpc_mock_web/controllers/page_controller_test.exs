defmodule GrpcMockWeb.PageControllerTest do
  use GrpcMockWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to GRPC Mock"
  end
end
