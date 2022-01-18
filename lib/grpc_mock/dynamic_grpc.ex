defmodule GrpcMock.DynamicGrpc do
  alias GrpcMock.DynamicGrpc.Server

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
