defmodule Seak.Messaging.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :count_users, :integer
    field :current_src, :string
    field :name, :string
    field :password, :string
    field :owner, :id

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :count_users, :current_src, :password, :owner])
    |> validate_required([:name, :count_users, :current_src, :password, :owner])
  end
end
