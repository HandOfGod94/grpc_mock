defmodule GrpcMock.DynamicCompiler.EExLoaderTest do
  use GrpcMock.MnesiaCase
  doctest GrpcMock.DynamicCompiler.EExLoader

  import GrpcMock.Factory

  alias GrpcMock.DynamicCompiler.EExLoader
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore

  @template :code.priv_dir(:grpc_mock) |> Path.join("dynamic_server.eex")
  @mnesia_table :dyn_module

  describe "load_modules/2 - error scenarios" do
    test "returns error when template is absent" do
      assert {:error, errors} = EExLoader.load_modules("invalid_template.eex", foo: "bar")
      assert [compile: %File.Error{reason: :enoent}] = errors
    end

    test "returns error when bindings are invalid" do
      assert {:error, errors} = EExLoader.load_modules(@template, app: "Foo", foo: :bar)
      assert [compile: %CompileError{}] = errors
    end
  end

  describe "load_modules/2 - when template and bindings are valid" do
    setup :load_proto_modules

    test "returns loader with modules_generated field set" do
      mocks = [{:say_hello, HelloReply, inspect(%{message: "hello world"})}]
      %{service: service} = build(:server)
      bindings = [app: "Greeter", service: service, mocks: mocks]

      assert {:ok, loader} = EExLoader.load_modules(@template, bindings)

      assert [
               {GrpcMock.DynamicServer.GreeterServer, 'elixir_grpcmock_dynamicserver_greeterserver', _},
               {Greeter.Endpoint, 'elixir_greeter_endpoint', _}
             ] = loader.modules_generated
    end
  end

  defp load_proto_modules(_) do
    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    proto_file = "helloworld.proto"
    ProtocLoader.load_modules(import_path, proto_file)

    :ok
  end
end
