defmodule GrpcMock.DynamicGrpc do
  def generate_implmentation(service, stubs) do
    mocks =
      Enum.map(stubs, fn stub ->
        {stub.method_name, stub.return_type, inspect(stub.data)}
      end)

    {content, _} =
      :code.priv_dir(:grpc_mock)
      |> Path.join("dynamic_server.eex")
      |> EEx.compile_file()
      |> Code.eval_quoted(app: app_name(service), service: service, mocks: mocks)

    Code.compile_string(content)
  end

  defp app_name(service_module) do
    Atom.to_string(service_module)
    |> String.split(".")
    |> Enum.at(-2)
  end
end
