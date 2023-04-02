defmodule SeakWeb.RoomLive.Show do
  use SeakWeb, :live_view

  alias Seak.Messaging
  alias SeakWeb.Presence

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    room = Messaging.get_room!(id)
    topic = "users:room:#{room.id}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Seak.PubSub, topic)

      {:ok, _} =
        Presence.track(
          self(),
          topic,
          socket.assigns.current_user.id,
          %{
            username: socket.assigns.current_user.email,
            playing: false,
            current_time: 0,
            current_src: room.current_src
          }
        )
    end

    presences = Presence.list(topic) |> simple_presence_map

    socket =
      socket
      |> assign(:presences, presences)
      |> assign(:username, socket.assigns.current_user.email)
      |> assign(:playing, false)
      |> assign(:current_time, 0)
      |> assign(:current_src, room.current_src)
      |> assign(:topic, topic)

    {:ok, socket}
  end

  defp simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {id, %{metas: [meta | _]}} -> {id, meta} end)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))

    assign(socket, :presences, presences)
  end

  defp remove_presences(socket, leaves) do
    ids = Enum.map(leaves, fn {id, _} -> id end)
    presences = Map.drop(socket.assigns.presences, ids)

    assign(socket, :presences, presences)
  end

  @impl true
  def handle_event("toggle_playing", _params, socket) do
    socket = socket |> update(:playing, fn playing -> !playing end)

    %{current_user: current_user} = socket.assigns
    %{metas: [meta | _]} = Presence.get_by_key(socket.assigns.topic, current_user.id)

    new_meta = %{meta | playing: socket.assigns.playing}
    Presence.update(self(), socket.assigns.topic, current_user.id, new_meta)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket = socket |> remove_presences(diff.leaves) |> add_presences(diff.joins)

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Messaging.get_room!(id))}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
