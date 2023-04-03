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

  defp sync_room(socket, meta) do
    %{current_user: current_user, room: room} = socket.assigns

    if current_user != room.owner do
      socket
      |> assign(:current_src, meta.current_src)
      |> assign(:current_time, meta.current_time)
    else
      socket
    end
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))

    %{owner: owner} = socket.assigns.room

    owner = to_string(owner)

    if owner in Map.keys(joins) do
      %{metas: [meta | _]} = joins[owner]
      sync_room(socket, meta) |> assign(:presences, presences)
    else
      socket |> assign(:presences, presences)
    end
  end

  defp remove_presences(socket, leaves) do
    ids = Enum.map(leaves, fn {id, _} -> id end)
    presences = Map.drop(socket.assigns.presences, ids)

    assign(socket, :presences, presences)
  end

  @impl true
  def handle_event("play_video", current_time, socket) do
    update_presence(socket, playing: true, current_time: current_time)

    {:noreply, socket |> assign(:playing, true) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_event("pause_video", current_time, socket) do
    update_presence(socket, playing: false, current_time: current_time)

    {:noreply, socket |> assign(:playing, false) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_event("seek_video", current_time, socket) do
    update_presence(socket, playing: false, current_time: current_time)

    {:noreply, socket |> assign(:playing, false) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket = socket |> remove_presences(diff.leaves) |> add_presences(diff.joins)

    {:noreply, socket}
  end

  @impl true
  def handle_info({_form_module, {:saved, room}}, socket) do
    {:ok, _} =
      update_presence(socket, current_src: room.current_src, current_time: 0, playing: false)

    socket =
      socket
      |> assign(:current_src, room.current_src)
      |> assign(:current_time, 0)
      |> assign(:playing, false)

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Messaging.get_room!(id))}
  end

  defp update_presence(socket, updates) do
    %{current_user: current_user, topic: topic} = socket.assigns
    %{metas: [meta | _]} = Presence.get_by_key(topic, current_user.id)

    new_meta = Enum.reduce(updates, meta, fn {key, value}, acc -> Map.put(acc, key, value) end)

    Presence.update(self(), topic, current_user.id, new_meta)
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
