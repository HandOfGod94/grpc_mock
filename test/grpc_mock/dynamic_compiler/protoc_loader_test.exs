defmodule GrpcMock.DynamicCompiler.ProtocLoaderTest do
  use ExUnit.Case, async: true
  doctest GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore

  @mnesia_table :dyn_module

  setup do
    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    :mnesia.create_table(@mnesia_table, ModulesStore.store_options())

    on_exit(fn ->
      :mnesia.transaction(fn -> :mnesia.clear_table(@mnesia_table) end)
    end)

    %{import_path: import_path}
  end

  describe "load_modules/2" do
    test "generates and save modules in mnesia", %{import_path: import_path} do
      proto_file = "helloworld.proto"
      result = ProtocLoader.load_modules(import_path, proto_file)

      modules = :mnesia.dirty_all_keys(@mnesia_table) |> MapSet.new()

      assert {:ok, _loader} = result

      assert MapSet.member?(modules, GrpcMock.Protos.Helloworld.HelloReply)
      assert MapSet.member?(modules, GrpcMock.Protos.Helloworld.Greeter.Service)
      assert MapSet.member?(modules, GrpcMock.Protos.Helloworld.Greeter.Stub)
      assert MapSet.member?(modules, GrpcMock.Protos.Helloworld.HelloRequest)
    end

    test "returns error when import path is incorrect" do
      import_path = "/invalid/dir"
      proto_file = "helloworld.proto"

      result = ProtocLoader.load_modules(import_path, proto_file)
      assert {:error, _} = result
    end

    test "returns error when proto file is incorrect", %{import_path: import_path} do
      proto_file = "foo.proto"

      result = ProtocLoader.load_modules(import_path, proto_file)
      assert {:error, _} = result
    end
  end
end
