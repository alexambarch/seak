defmodule Seak.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :count_users, :integer
      add :current_src, :string
      add :password, :string
      add :owner, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:rooms, [:owner])
  end
end
