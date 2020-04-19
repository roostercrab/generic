defmodule GenericWeb.Schema do
  use Absinthe.Schema

  alias Generic.{Thing, Repo}

  query do
    field :things, list_of(:thing) do
      resolve(fn _, _, _ ->
        {:ok, Repo.all(Thing.Item)}
      end)
    end
  end

  object :thing do
    field :id, :id
    field :name, :string
    field :description, :string
  end
end
