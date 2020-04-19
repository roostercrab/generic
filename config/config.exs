# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :generic,
  ecto_repos: [Generic.Repo]

# Configures the endpoint
config :generic, GenericWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/xxp4a4NzweMgrZad+syUVi9EyqtuRatfM5xFPxneiofD7y3+gBNAtankYjPVNk8",
  render_errors: [view: GenericWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Generic.PubSub,
  live_view: [signing_salt: "WmLAOxUt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
