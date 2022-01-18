defmodule GrpcMock.Application do
  @moduledoc false

  use Application
  alias GrpcMock.PbDynamicCompiler

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      GrpcMockWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: GrpcMock.PubSub},
      # Start the Endpoint (http/https)
      GrpcMockWeb.Endpoint,
      # Start a worker by calling: GrpcMock.Worker.start_link(arg)
      PbDynamicCompiler,
      {Registry, keys: :unique, name: GrpcMock.ServerRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: GrpcMock.DynamicGrpc.DynamicSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GrpcMock.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GrpcMockWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
