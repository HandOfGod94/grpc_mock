defmodule GrpcMock.DynamicServer.ImplmentationGenerator do
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicCompiler.EExLoader

  def generate(%Server{} = server, template) do
    with {:ok, mocks} <- set_method_body(server.mock_responses),
         bindings <- [app: app_name(server.service), service: server.service, mocks: mocks],
         {_, modules} when is_list(modules) <- EExLoader.load_modules(template, bindings) do
      {:ok, modules}
    end
  end

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
