defmodule GrpcMock.DynamicGrpc do
  alias GrpcMock.DynamicGrpc.Server
  alias GrpcMock.DynamicGrpc.DynamicSupervisor

  require Logger

  @registry GrpcMock.ServerRegistry
  @otp_app :grpc_mock

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

  def change_dynamic_server(server, params \\ %{}) do
    Server.changeset(server, params)
  end

  def generate_implmentation(%Server{} = server) do
    with mocks <- create_mocks(server.mock_responses),
         :ok <- accumulate_errors(mocks) do
      {content, _} =
        :code.priv_dir(@otp_app)
        |> Path.join("dynamic_server.eex")
        |> EEx.compile_file()
        |> Code.eval_quoted(app: app_name(server.service), service: server.service, mocks: mocks)

      Code.compile_string(content)
    end
  end

  defp app_name(service_module) do
    service_module
    |> String.split(".")
    |> Enum.at(-2)
  end

  defp create_mocks(mock_responses) do
    Enum.reduce(mock_responses, [], fn resp, acc ->
      case Jason.decode(resp.data, keys: :atoms) do
        {:ok, data} ->
          stub = {resp.method, resp.return_type, inspect(data)}
          [stub | acc]

        {:error, error} ->
          [{:error, error} | acc]
      end
    end)
  end

  defp accumulate_errors(mocks) do
    errors =
      Enum.reduce(mocks, [], fn
        {:error, error}, acc -> acc ++ [error]
        _otherwise, acc -> acc
      end)

    IO.inspect(errors)
    if errors != [] do
      {:error, errors}
    else
      :ok
    end
  end
end
