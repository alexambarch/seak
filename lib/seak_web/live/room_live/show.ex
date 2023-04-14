defmodule SeakWeb.RoomLive.Show do
  use SeakWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Seak.Messaging
  alias SeakWeb.Presence

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    room = Messaging.get_room!(id)

    topic = %{
      video: "room:#{room.id}:video",
      chat: "room:#{room.id}:chat",
      presence: "room:#{room.id}:presence"
    }

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Seak.PubSub, topic.presence)
      Phoenix.PubSub.subscribe(Seak.PubSub, topic.chat)
      Phoenix.PubSub.subscribe(Seak.PubSub, topic.video)

      {:ok, _} =
        Presence.track(
          self(),
          topic.presence,
          socket.assigns.current_user.id,
          %{
            username: socket.assigns.current_user.email,
            video_state: :waiting
          }
        )
    end

    presences = Presence.list(topic.presence) |> simple_presence_map

    socket =
      socket
      |> assign(:messages, [])
      |> assign(:presences, presences)
      |> assign(:video_state, :paused)
      |> assign(:topic, topic)
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
    socket =
      socket
      |> assign(video_state: :playing)
      |> assign(current_time: current_time)
      |> update_presence(video_state: :playing)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.topic.video,
      {:playing, current_time, socket.assigns.current_user}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("pause_video", current_time, socket) do
    socket =
      socket
      |> assign(video_state: :paused)
      |> assign(current_time: current_time)
      |> update_presence(video_state: :paused)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.topic.video,
      {:paused, current_time, socket.assigns.current_user}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("seeking_video", current_time, socket) do
    socket =
      socket
      |> assign(video_state: :seeking)
      |> assign(current_time: current_time)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.topic.video,
      {:seeking, current_time, socket.assigns.current_user}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("canplay_video", _current_time, socket) do
    socket =
      socket
      |> assign(video_state: :paused)
      |> update_presence(video_state: :paused)

    {:noreply, socket}
  end

  @impl true
  def handle_event("waiting_video", current_time, socket) do
    socket =
      socket
      |> assign(video_state: :waiting)
      |> assign(current_time: current_time)
      |> update_presence(video_state: :waiting)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.topic.video,
      {:paused, current_time, socket.assigns.current_user}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_presence", status, socket) do
    new_status = String.to_atom(status)

    socket =
      socket
      |> assign(video_state: new_status)
      |> update_presence(video_state: new_status)

    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    email = socket.assigns.current_user.email

    index =
      email
      |> String.graphemes()
      |> Enum.find_index(fn c -> c == "@" end)

    message = %SeakWeb.RoomLive.Message{from: String.slice(email, 0..(index - 1)), body: message}
    Phoenix.PubSub.broadcast(Seak.PubSub, socket.assigns.topic.chat, {:message, message})

    {:noreply, socket}
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
  def handle_info({:seeking, current_time, current_user}, socket) do
    if current_user != socket.assigns.current_user do
      socket =
        socket
        |> push_event("seek", %{current_time: current_time})
        |> put_flash(:warning, "#{current_user.email} has seeked.")

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket = socket |> remove_presences(diff.leaves) |> add_presences(diff.joins)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:change_src, src}, socket) do
    socket = socket |> assign(current_src: src)

    {:noreply, socket}
  end

  @impl true
  def handle_info({_form_module, {:saved, room}}, socket) do
    socket =
      socket
      |> assign(current_src: room.current_src)
      |> assign(video_state: :paused)
      |> update_presence(video_state: :paused)

    Phoenix.PubSub.broadcast(
      Seak.PubSub,
      socket.assigns.topic.video,
      {:change_src, room.current_src}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:message, message}, socket) do
    socket = socket |> assign(messages: [message | socket.assigns.messages])
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
    %{current_user: current_user, topic: %{presence: topic}} = socket.assigns
    %{metas: [meta | _]} = Presence.get_by_key(topic, current_user.id)

    new_meta = Enum.reduce(updates, meta, fn {key, value}, acc -> Map.put(acc, key, value) end)

    Presence.update(self(), topic, current_user.id, new_meta)

    socket
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
