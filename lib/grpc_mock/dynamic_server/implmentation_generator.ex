defmodule GrpcMock.DynamicServer.ImplmentationGenerator do
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicCompiler.EExLoader

  def generate(%Server{service: service, mock_responses: mock_responses}, template)
      when service != nil and
             mock_responses != nil and
             mock_responses != [] and
             template != nil do
    with {:ok, mocks} <- set_method_body(mock_responses),
         bindings <- [app: app_name(service), service: service, mocks: mocks],
         {:ok, %{modules_generated: modules}} <- EExLoader.load_modules(template, bindings) do
      {:ok, modules}
    end
  end

  def generate(_, _), do: {:error, :invalid_server_info}

  defp set_method_body(mock_responses) do
    mock_responses
    |> Enum.reduce_while([], fn resp, acc ->
      case Jason.decode(resp.data, keys: :atoms) do
        {:ok, decoded} -> {:cont, [{resp.method, resp.return_type, inspect(decoded)} | acc]}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:error, error} -> {:error, error}
      otherwise -> {:ok, otherwise}
    end
  end

  defp app_name(service_module) do
    service_module
    |> String.split(".")
    |> Enum.at(-2)
  end
end
