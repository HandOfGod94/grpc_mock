defmodule GrpcMockWeb.ProtocModuleLiveTest do
  use GrpcMockWeb.ConnCase

  import Phoenix.LiveViewTest
  import GrpcMock.PbDynamicCompilerFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_protoc_module(_) do
    protoc_module = protoc_module_fixture()
    %{protoc_module: protoc_module}
  end

  describe "Index" do
    setup [:create_protoc_module]

    test "lists all protoc_modules", %{conn: conn, protoc_module: protoc_module} do
      {:ok, _index_live, html} = live(conn, Routes.protoc_module_index_path(conn, :index))

      assert html =~ "Listing Protoc modules"
      assert html =~ protoc_module.name
    end

    test "saves new protoc_module", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.protoc_module_index_path(conn, :index))

      assert index_live |> element("a", "New Protoc module") |> render_click() =~
               "New Protoc module"

      assert_patch(index_live, Routes.protoc_module_index_path(conn, :new))

      assert index_live
             |> form("#protoc_module-form", protoc_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#protoc_module-form", protoc_module: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.protoc_module_index_path(conn, :index))

      assert html =~ "Protoc module created successfully"
      assert html =~ "some name"
    end

    test "updates protoc_module in listing", %{conn: conn, protoc_module: protoc_module} do
      {:ok, index_live, _html} = live(conn, Routes.protoc_module_index_path(conn, :index))

      assert index_live |> element("#protoc_module-#{protoc_module.id} a", "Edit") |> render_click() =~
               "Edit Protoc module"

      assert_patch(index_live, Routes.protoc_module_index_path(conn, :edit, protoc_module))

      assert index_live
             |> form("#protoc_module-form", protoc_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#protoc_module-form", protoc_module: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.protoc_module_index_path(conn, :index))

      assert html =~ "Protoc module updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes protoc_module in listing", %{conn: conn, protoc_module: protoc_module} do
      {:ok, index_live, _html} = live(conn, Routes.protoc_module_index_path(conn, :index))

      assert index_live |> element("#protoc_module-#{protoc_module.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#protoc_module-#{protoc_module.id}")
    end
  end

  describe "Show" do
    setup [:create_protoc_module]

    test "displays protoc_module", %{conn: conn, protoc_module: protoc_module} do
      {:ok, _show_live, html} = live(conn, Routes.protoc_module_show_path(conn, :show, protoc_module))

      assert html =~ "Show Protoc module"
      assert html =~ protoc_module.name
    end

    test "updates protoc_module within modal", %{conn: conn, protoc_module: protoc_module} do
      {:ok, show_live, _html} = live(conn, Routes.protoc_module_show_path(conn, :show, protoc_module))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Protoc module"

      assert_patch(show_live, Routes.protoc_module_show_path(conn, :edit, protoc_module))

      assert show_live
             |> form("#protoc_module-form", protoc_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#protoc_module-form", protoc_module: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.protoc_module_show_path(conn, :show, protoc_module))

      assert html =~ "Protoc module updated successfully"
      assert html =~ "some updated name"
    end
  end
end
