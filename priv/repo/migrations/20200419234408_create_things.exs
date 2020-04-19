defmodule Generic.Repo.Migrations.CreateThings do
  use Ecto.Migration

  def change do
    create table(:things) do
      add :name, :string
      add :description, :string

      timestamps()
    end

  end
end
