defmodule Seak.MessagingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Seak.Messaging` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        count_users: 42,
        current_src: "some current_src",
        name: "some name",
        password: "some password"
      })
      |> Seak.Messaging.create_room()

    room
  end
end
