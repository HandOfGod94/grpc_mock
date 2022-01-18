defmodule GrpcMock.DynamicGrpc do
  alias GrpcMock.DynamicGrpc.Server
  alias GrpcMock.DynamicGrpc.DynamicSupervisor

  require Logger

  @registry GrpcMock.ServerRegistry

  @moduledoc """
  format in which servers are stored in registry:
  {key, pid, serverstrucct} where key == Nanoid
  """

  def list_all_servers do
    match_pattern = {:_, :"$1", :"$2"}
    guards = []
    body = [%{pid: :"$1", server: :"$2"}]

    queryspec = [{match_pattern, guards, body}]
    Registry.select(@registry, queryspec)
  end

  def fetch_server(id) do
    case Registry.lookup(@registry, id) do
      [{pid, value}] -> {pid, value}
      _ -> nil
    end
  end

  def start_server(%Server{} = server) do
    with [_, {endpoint, _}] <- generate_implmentation(server),
         {:ok, _} <- DynamicSupervisor.start_server(server, endpoint) do
      {:ok, server}
    else
      {:error, %Ecto.Changeset{} = errors} -> {:error, errors}
      {:error, error} -> {:error, {:failed_to_start_server, inspect(error)}}
    end
  end

  def stop_server(id) do
    with {pid, server} <- fetch_server(id),
         :ok <- DynamicSupervisor.stop_server(pid) do
      Logger.info("successfully stopped server")
      {:ok, server}
    end
  end

  def generate_implmentation(%Server{} = server) do
    mocks =
      Enum.map(server.mock_responses, fn stub ->
        {stub.method, stub.return_type, inspect(stub.data)}
      end)

    {content, _} =
      :code.priv_dir(:grpc_mock)
      |> Path.join("dynamic_server.eex")
      |> EEx.compile_file()
      |> Code.eval_quoted(app: app_name(server.service), service: server.service, mocks: mocks)

    Code.compile_string(content)
  end

  defp app_name(service_module) do
    service_module
    |> String.split(".")
    |> Enum.at(-2)
  end
end
