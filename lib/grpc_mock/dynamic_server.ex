defmodule GrpcMock.DynamicServer do
  import GrpcMock.DynamicServer.Servergen

  alias Registry
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicSupervisor
  alias GrpcMock.DynamicServer.Servergen

  require Logger

  defmodule StartFailedError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to start server. reason: #{inspect(reason)}"
  end

  @registry GrpcMock.ServerRegistry

  @spec list_all_servers() :: list(Server.t())
  def list_all_servers do
    match_pattern = {:_, :"$1", :"$2"}
    guards = []
    body = [%{pid: :"$1", server: :"$2"}]

    queryspec = [{match_pattern, guards, body}]
    Registry.select(@registry, queryspec)
  end

  @spec fetch_server(Server.id()) :: {pid(), Server.t()} | nil
  def fetch_server(id) do
    case Registry.lookup(@registry, id) do
      [{pid, value}] -> {pid, value}
      _ -> nil
    end
  end

  @template :code.priv_dir(:grpc_mock) |> Path.join("dynamic_server.eex")
  def start_server(servergen, server_params) do
    servergen =
      servergen
      |> build_server_struct(server_params)
      |> generate_implmentation(template: @template)
      |> launch()
      |> apply_instruction()

    cond do
      servergen.valid? -> {:ok, servergen.server}
      Servergen.changeset_error(servergen) != nil -> {:error, Servergen.changeset_error(servergen)}
      true -> {:error, %StartFailedError{reason: servergen.errors}}
    end
  end

  @spec stop_server(Server.id()) :: {:ok, Server.t()} | {:error, :not_found} | nil
  def stop_server(id) do
    with {pid, server} <- fetch_server(id),
         :ok <- DynamicSupervisor.stop_server(pid) do
      Logger.info("successfully stopped server")
      {:ok, server}
    end
  end
end
