defmodule SeakWeb.RoomLive.Index do
  use SeakWeb, :live_view

  alias Seak.Messaging
  alias Seak.Messaging.Room

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rooms, Messaging.list_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Messaging.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_info({SeakWeb.RoomLive.FormComponent, {:saved, room}}, socket) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Messaging.get_room!(id)
    {:ok, _} = Messaging.delete_room(room)

    {:noreply, stream_delete(socket, :rooms, room)}
  end
end
