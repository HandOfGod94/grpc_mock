defmodule GrpcMock.DynamicCompiler.EExLoaderTest do
  use ExUnit.Case
  doctest GrpcMock.DynamicCompiler.EExLoader

  import GrpcMock.Factory

  alias GrpcMock.DynamicCompiler.EExLoader
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore

  @template :code.priv_dir(:grpc_mock) |> Path.join("dynamic_server.eex")
  @mnesia_table :dyn_module

  setup do
    :mnesia.create_table(@mnesia_table, ModulesStore.store_options())

    on_exit(fn ->
      :mnesia.transaction(fn -> :mnesia.clear_table(@mnesia_table) end)
    end)

    :ok
  end

  describe "load_modules/2" do
    test "return codegen with error when template is absent" do
      assert {:error, errors} = EExLoader.load_modules("invalid_template.eex", foo: "bar")
      assert [compile: %File.Error{reason: :enoent}] = errors
    end

    test "returns codegen with error when bindings are invalid" do
      assert {:error, errors} = EExLoader.load_modules(@template, app: "Foo", foo: :bar)
      assert [compile: %CompileError{}] = errors
    end

    test "sets modules_generated when template and bindings are valid" do
      load_test_proto_modules()

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

  defp load_test_proto_modules do
    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    proto_file = "helloworld.proto"
    ProtocLoader.load_modules(import_path, proto_file)
  end
end
