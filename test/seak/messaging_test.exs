defmodule Seak.MessagingTest do
  use Seak.DataCase

  alias Seak.Messaging

  describe "rooms" do
    alias Seak.Messaging.Room

    import Seak.MessagingFixtures

    @invalid_attrs %{count_users: nil, current_src: nil, name: nil, password: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Messaging.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Messaging.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      valid_attrs = %{count_users: 42, current_src: "some current_src", name: "some name", password: "some password"}

      assert {:ok, %Room{} = room} = Messaging.create_room(valid_attrs)
      assert room.count_users == 42
      assert room.current_src == "some current_src"
      assert room.name == "some name"
      assert room.password == "some password"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Messaging.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{count_users: 43, current_src: "some updated current_src", name: "some updated name", password: "some updated password"}

      assert {:ok, %Room{} = room} = Messaging.update_room(room, update_attrs)
      assert room.count_users == 43
      assert room.current_src == "some updated current_src"
      assert room.name == "some updated name"
      assert room.password == "some updated password"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Messaging.update_room(room, @invalid_attrs)
      assert room == Messaging.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Messaging.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Messaging.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Messaging.change_room(room)
    end
  end
end
