import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :grpc_mock, GrpcMockWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "sJm7EA5YxxT4HOSSYHnDjn9ssYsg2M3R2pcD+2x1Pfjs3pVcTf5a8LrXN/LBQg8W",
  server: false

# In test we don't send emails.
config :grpc_mock, GrpcMock.Mailer, adapter: Swoosh.Adapters.Test

config :grpc_mock,
  proto_out_dir: System.tmp_dir!()

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
config :grpc, start_server: false
