defmodule SeakWeb.RoomLive.ChatComponent do
  use SeakWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-[36rem] w-96 flex flex-col justify-between">
      <div class="h-full rounded-xl bg-zinc-200 overflow-auto">
        <div :for={message <- @messages}>
          <strong><%= message.from %>:&nbsp;</strong>
          <%= message.body %>
        </div>
      </div>
      <.simple_form for={@form} phx-submit="send_message">
        <.input field={@form[:message]} placeholder="Send a message..." />
        <:actions>
          <.button>Send</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("send_message", message, socket) do
    send(self(), {__MODULE__, {:message, message}})

    {:noreply, socket}
  end
end
