defmodule Generic.Thing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "things" do
    field :description, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(thing, attrs) do
    thing
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
  end
end
