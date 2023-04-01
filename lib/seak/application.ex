defmodule Seak.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SeakWeb.Telemetry,
      # Start the Ecto repository
      Seak.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Seak.PubSub},
      # Start Finch
      {Finch, name: Seak.Finch},
      # Start the Endpoint (http/https)
      SeakWeb.Endpoint
      # Start a worker by calling: Seak.Worker.start_link(arg)
      # {Seak.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Seak.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SeakWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
