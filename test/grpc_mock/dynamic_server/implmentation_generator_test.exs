defmodule GrpcMock.DynamicServer.ImplmentationGeneratorTest do
  use GrpcMock.MnesiaCase, async: true
  doctest GrpcMock.DynamicServer.ImplmentationGenerator
  import GrpcMock.Factory
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicServer.ImplmentationGenerator

  @template :code.priv_dir(:grpc_mock) |> Path.join("dynamic_server.eex")

  setup_all :load_proto_modules

  describe "generate/2" do
    test "returns error when server info is invalid" do
      server = build(:server)
      assert {:error, compile: %File.Error{}} = ImplmentationGenerator.generate(server, "/invalid/dir/template.eex")
    end

    test "returns error when template is invalid" do
      server = build(:server, service: "Invalid.Service")
      assert {:error, _} = ImplmentationGenerator.generate(server, @template)
    end

    test "when server info and template are valid, returns list of modules generated" do
      server = build(:server)

      assert {:ok,
              [
                {GrpcMock.DynamicServer.GreeterServer, 'elixir_grpcmock_dynamicserver_greeterserver', _},
                {Greeter.Endpoint, 'elixir_greeter_endpoint', _}
              ]} = ImplmentationGenerator.generate(server, @template)
    end
  end

  defp load_proto_modules(_) do
    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    proto_file = "helloworld.proto"
    {:ok, modules} = ProtocLoader.load_modules(import_path, proto_file)

    %{proto_modules: modules}
  end
end
