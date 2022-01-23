defmodule GrpcMock.Application do
  # credo:disable-for-this-file

  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    hosts = [:"main@Gahan-Rakholia", :"other@Gahan-Rakholia"]

    topologies = [
      grpc_mock: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: hosts]
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: GrpcMock.ClusterSupervisor]]},
      {Mnesiac.Supervisor, [hosts, [name: GrpcMock.MnesiacSupervisor]]},
      # Start the Telemetry supervisor
      GrpcMockWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: GrpcMock.PubSub},
      # Start the Endpoint (http/https)
      GrpcMockWeb.Endpoint,
      # Start a worker by calling: GrpcMock.Worker.start_link(arg)
      {Task.Supervisor, name: GrpcMock.TaskSupervisor},
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
  @impl Application
  def config_change(changed, _new, removed) do
    GrpcMockWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
