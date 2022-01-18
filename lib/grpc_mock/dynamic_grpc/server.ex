defmodule GrpcMock.DynamicGrpc.Server do
  def generate_implmentation(mock) do
    methods = get_in(mock.responses, [Access.all(), Access.key(:method_name)])
    resp_structs = get_in(mock.responses, [Access.all(), Access.key(:return_type)])
    data = get_in(mock.responses, [Access.all(), Access.key(:data)])

    mocks = Enum.zip([methods, resp_structs, data])

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
