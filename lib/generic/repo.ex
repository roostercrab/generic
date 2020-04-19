defmodule Generic.Repo do
  use Ecto.Repo,
    otp_app: :generic,
    adapter: Ecto.Adapters.Postgres
end
