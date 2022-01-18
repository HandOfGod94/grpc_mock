defmodule GrpcMock.DynamicGrpc.Server do
  def generate_implmentation(mock) do
    mocks =
      Enum.map(mock.responses, fn response ->
        {response.method_name, response.return_type, inspect(response.data)}
      end)

    {content, _} =
      :code.priv_dir(:grpc_mock)
      |> Path.join("dynamic_server.eex")
      |> EEx.compile_file()
      |> Code.eval_quoted(app: app_name(mock.service), service: mock.service, mocks: mocks)

    Code.compile_string(content)
  end

  defp app_name(service_module) do
    Atom.to_string(service_module)
    |> String.split(".")
    |> Enum.at(-2)
  end
end
