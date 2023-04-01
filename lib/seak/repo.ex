defmodule Seak.Repo do
  use Ecto.Repo,
    otp_app: :seak,
    adapter: Ecto.Adapters.Postgres
end
