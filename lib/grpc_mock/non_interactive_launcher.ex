defmodule GrpcMock.NonInteractiveLauncher do
  require Logger

  use Task, restart: :transient

  alias GrpcMock.DynamicCompiler
  alias GrpcMock.DynamicServer
  alias GrpcMock.DynamicServer.Servergen

  @type app_mode :: :interactive | :non_interactive
  @type launch_args :: %{app_mode: app_mode(), launch_config: map()}

  @spec start_link(any()) :: {:ok, pid}
  def start_link(args) do
    Task.start_link(__MODULE__, :run, [args])
  end

  @spec run(launch_args()) :: :ok
  def run(%{app_mode: :interactive}) do
    Logger.info("The app is running in interactive mode. Use web UI to load and start mock servers")
  end

  def run(%{app_mode: :non_interactive, launch_config: launch_config}) do
    Logger.info("The app is running in non-interactive mode. Launching mock server based on yaml config")

    %{
      "loader" => %{
        "import_path" => import_path,
        "file" => file
      },
      "server" => server_params
    } = Enum.at(launch_config, 0)

    with {:ok, _} <- DynamicCompiler.load_for_proto_sync(import_path, file),
         {:ok, _} <- DynamicServer.start_server(%Servergen{}, server_params) do
      Logger.info("successfully started grpc mock server")
    else
      error -> Logger.error("failed to start mock server. #{inspect(error)}")
    end
  end
end
