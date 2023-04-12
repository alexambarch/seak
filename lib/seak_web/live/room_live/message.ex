defmodule SeakWeb.RoomLive.Message do
  use Ecto.Schema
  import Ecto.Changeset

  defstruct([:from, :body])

  def changeset(data, _types \\ %{}) do
    data
    |> validate_length(:body, min: 1, max: 255)
  end
end
