defmodule SeakWeb.RoomLive.Show do
  use SeakWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Seak.Messaging
  alias SeakWeb.Presence

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    room = Messaging.get_room!(id)
    presence_topic = "users:room:#{room.id}:presences"
    chat_topic = "users:room:#{room.id}:chat"
    video_topic = "users:room:#{room.id}:video"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Seak.PubSub, presence_topic)
      Phoenix.PubSub.subscribe(Seak.PubSub, chat_topic)
      Phoenix.PubSub.subscribe(Seak.PubSub, video_topic)

      {:ok, _} =
        Presence.track(
          self(),
          presence_topic,
          socket.assigns.current_user.id,
          %{
            username: socket.assigns.current_user.email,
            video_state: :paused
          }
        )
    end

    presences = Presence.list(presence_topic) |> simple_presence_map

    socket =
      socket
      |> assign(:messages, [])
      |> assign(:presences, presences)
      |> assign(:video_state, :paused)
      |> assign(:presence_topic, presence_topic)
      |> assign(:chat_topic, chat_topic)
      |> assign(:video_topic, video_topic)
      |> assign(:current_time, 0)
      |> assign(:current_src, room.current_src)

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
  def handle_event("play_video", current_time, socket) do
    update_presence(socket, video_state: :playing)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.video_topic,
      {:playing, current_time, socket.assigns.current_user}
    )

    {:noreply, socket |> assign(:video_state, :playing) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_event("pause_video", current_time, socket) do
    update_presence(socket, video_state: :paused)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.video_topic,
      {:paused, current_time, socket.assigns.current_user}
    )

    {:noreply, socket |> assign(:video_state, :paused) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_event("seeked_video", current_time, socket) do
    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.video_topic,
      {:seeked, current_time, socket.assigns.current_user}
    )

    {:noreply, socket |> assign(:video_state, :seeked) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_event("waiting_video", current_time, socket) do
    update_presence(socket, video_state: :paused)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.video_topic,
      {:paused, current_time, socket.assigns.current_user}
    )

    {:noreply, socket |> assign(:video_state, :paused) |> assign(current_time: current_time)}
  end

  @impl true
  def handle_info({:playing, current_time, current_user}, socket) do
    if current_user != socket.assigns.current_user do
      socket = socket |> push_event("startPlaying", %{current_time: current_time})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:paused, current_time, current_user}, socket) do
    if current_user != socket.assigns.current_user do
      socket = socket |> push_event("stopPlaying", %{current_time: current_time})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:seeked, current_time, _current_user}, socket) do
    socket = socket |> push_event("seek", %{current_time: current_time})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:ready, _current_time}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket = socket |> remove_presences(diff.leaves) |> add_presences(diff.joins)

    {:noreply, socket}
  end

  @impl true
  def handle_info({_form_module, {:saved, room}}, socket) do
    {:ok, _} = update_presence(socket, video_state: false)

    socket =
      socket
      |> assign(:current_src, room.current_src)
      |> assign(:current_time, 0)
      |> assign(:video_state, false)

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
    %{current_user: current_user, presence_topic: topic} = socket.assigns
    %{metas: [meta | _]} = Presence.get_by_key(topic, current_user.id)

    new_meta = Enum.reduce(updates, meta, fn {key, value}, acc -> Map.put(acc, key, value) end)

    Presence.update(self(), topic, current_user.id, new_meta)
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
