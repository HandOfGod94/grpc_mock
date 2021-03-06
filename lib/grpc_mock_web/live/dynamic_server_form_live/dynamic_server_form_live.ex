defmodule GrpcMockWeb.DynamicServerFormLive do
  use GrpcMockWeb, :live_view

  alias GrpcMock.DynamicServer
  alias GrpcMock.DynamicServer.Servergen
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicServer.MockResponse

  @impl Phoenix.LiveView
  def render(assigns) do
    Phoenix.View.render(GrpcMockWeb.DynamicServerView, "form.html", assigns)
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    empty_changeset =
      %Server{}
      |> Server.changeset()
      |> Ecto.Changeset.put_embed(:mock_responses, [%MockResponse{}])

    {:ok, assign(socket, %{changeset: empty_changeset, errors: ""})}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"server" => params}, socket) do
    changeset =
      %Server{}
      |> Server.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"server" => params}, socket) do
    case DynamicServer.start_server(Servergen.new(), params) do
      {:ok, server} ->
        {:noreply,
         socket
         |> put_flash(:info, "Dynamic server created successfully.")
         |> redirect(to: Routes.dynamic_server_path(GrpcMockWeb.Endpoint, :show, server))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, error} ->
        {:noreply, assign(socket, errors: Exception.message(error))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("add-mock-response", _, socket) do
    exisiting_changeset = socket.assigns.changeset
    existing_responses = Map.get(exisiting_changeset.changes, :mock_responses)

    new_responses =
      existing_responses
      |> Enum.concat([%MockResponse{}])

    changeset =
      exisiting_changeset
      |> Ecto.Changeset.put_embed(:mock_responses, new_responses)

    {:noreply, assign(socket, changeset: changeset)}
  end
end
