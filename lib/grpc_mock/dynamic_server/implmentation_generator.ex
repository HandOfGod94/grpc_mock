defmodule GrpcMock.DynamicServer.ImplmentationGenerator do
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicCompiler.EExLoader
  alias GrpcMock.DynamicCompiler.Codegen

  defmodule Error do
    defexception [:reason, :field]
    @impl Exception
    def message(%__MODULE__{reason: :invalid_app_name}), do: "Invalid app_name. Failed to generate implmentation"
    def message(%__MODULE__{reason: :invalid_server_info}), do: "Invalid server_info. Failed to generate implmentation"
  end

  @spec generate(Server.t(), filename :: String.t()) :: {:ok, [Codegen.dynamic_module()]} | {:error, any()}
  def generate(%Server{service: service, mock_responses: mock_responses}, template)
      when service != nil and
             mock_responses != nil and
             mock_responses != [] and
             template != nil do
    with {:ok, mocks} <- set_method_body(mock_responses),
         {:ok, app} <- app_name(service),
         bindings <- [app: app, service: service, mocks: mocks],
         {:ok, %{modules_generated: modules}} <- EExLoader.load_modules(template, bindings) do
      {:ok, modules}
    end
  end

  def generate(_, _), do: {:error, %Error{reason: :invalid_server_info}}

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
    if String.ends_with?(service_module, ".Service") do
      {:ok,
       service_module
       |> String.split(".")
       |> Enum.at(-2)}
    else
      {:error, %Error{reason: :invalid_app_name}}
    end
  end
end
