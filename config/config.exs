# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :grpc_mock, GrpcMockWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: GrpcMockWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GrpcMock.PubSub,
  live_view: [signing_salt: "tGAWMwR/"]

config :grpc_mock,
  proto_out_dir: "./tmp",
  compile_status_updates_topic: "compile_status_updates"

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :grpc_mock, GrpcMock.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :grpc, start_server: true

# Mnesia datastore config
config :mnesiac,
  dir: './mnesia/#{node()}',
  stores: [GrpcMock.DynamicCompiler.Codegen.Modules.Store],
  schema_type: :ram_copies

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
