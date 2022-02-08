defmodule GrpcMock.Application do
  # credo:disable-for-this-file
  require Logger

  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore

  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    # TODO: add wait for tables check
    :mnesia.create_table(:dyn_module, ModulesStore.store_options())

    Logger.info("App Mode: #{inspect(app_mode())}")
    Logger.info("Launch config: #{inspect(launch_config())}")

    children = [
      GrpcMockWeb.Telemetry,
      {Phoenix.PubSub, name: GrpcMock.PubSub},
      # Start the Endpoint (http/https)
      GrpcMockWeb.Endpoint,
      {Registry, keys: :unique, name: GrpcMock.ServerRegistry},
      {Task.Supervisor, name: GrpcMock.TaskSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: GrpcMock.DynamicSupervisor},
      {GrpcMock.NonInteractiveLauncher, %{app_mode: app_mode(), launch_config: launch_config()}}
    ]

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

  defp app_mode, do: Application.get_env(:grpc_mock, :app_mode)
  defp launch_config, do: Application.get_env(:grpc_mock, :launch_config)
end
