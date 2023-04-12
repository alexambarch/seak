defmodule SeakWeb.RoomLive.ChatComponent do
  use SeakWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full w-full flex flex-col items-stretch">
      <div class="space-y-1">
        <span :for={message <- @messages}>
          <strong><%= message.from %>:&nbsp;</strong>
          <%= message.body %>
        </span>
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
