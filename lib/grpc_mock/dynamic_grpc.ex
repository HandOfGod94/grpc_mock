defmodule GrpcMock.DynamicGrpc do
  alias GrpcMock.DynamicGrpc.Server
  alias GrpcMock.DynamicGrpc.DynamicSupervisor

  require Logger

  defmodule StartFailedError do
    defexception [:reason]
    @impl Exception
    def message(%{reason: reason}), do: "failed to start server. reason: #{inspect(reason)}"
  end

  @registry GrpcMock.ServerRegistry
  @otp_app :grpc_mock

  @moduledoc """
  format in which servers are stored in registry:
  {key, pid, serverstrucct} where key == Nanoid
  """

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

  @spec start_server(Server.t()) :: {:ok, Server.t()} | {:error, any()}
  def start_server(%Server{} = server) do
    with [_, {endpoint, _}] <- generate_implmentation(server),
         {:ok, _} <- DynamicSupervisor.start_server(server, endpoint) do
      {:ok, server}
    else
      {:error, %Ecto.Changeset{} = errors} -> {:error, errors}
      {:error, error} -> {:error, %StartFailedError{reason: error}}
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

  @spec change_dynamic_server(Server.t(), map()) :: Ecto.Changeset.t()
  def change_dynamic_server(server, params \\ %{}) do
    Server.changeset(server, params)
  end

  defp generate_implmentation(%Server{} = server) do
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

    if errors != [] do
      {:error, errors}
    else
      :ok
    end
  end
end
