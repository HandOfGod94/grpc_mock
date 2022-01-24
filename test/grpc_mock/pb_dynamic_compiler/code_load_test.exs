defmodule GrpcMock.PbDynamicCompiler.CodeLoadTest do
  use ExUnit.Case, async: false
  doctest GrpcMock.PbDynamicCompiler.CodeLoad
  alias GrpcMock.PbDynamicCompiler.CodeLoad
  alias GrpcMock.PbDynamicCompiler.CodeLoad.CodeLoadError

  setup do
    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    Mnesiac.init_mnesia(node())

    on_exit(fn ->
      :mnesia.transaction(fn -> :mnesia.clear_table(:module) end)
    end)

    %{import_path: import_path}
  end

  describe "load_modules_from_proto/2" do
    test "generates and save modules in mnesia", %{import_path: import_path} do
      proto_file = "helloworld.proto"
      result = CodeLoad.load_modules_from_proto(import_path, proto_file)

      modules = :mnesia.dirty_all_keys(:module)

      assert result == :ok

      assert modules == [
               GprcMock.Protos.Helloworld.HelloReply,
               GprcMock.Protos.Helloworld.Greeter.Service,
               GprcMock.Protos.Helloworld.Greeter.Stub,
               GprcMock.Protos.Helloworld.HelloRequest
             ]
    end

    test "returns error when import path is incorrect" do
      import_path = "/invalid/dir"
      proto_file = "helloworld.proto"

      result = CodeLoad.load_modules_from_proto(import_path, proto_file)
      assert {:error, %CodeLoadError{}} = result
    end

    test "returns error when proto file is incorrect", %{import_path: import_path} do
      proto_file = "foo.proto"

      result = CodeLoad.load_modules_from_proto(import_path, proto_file)
      assert {:error, %CodeLoadError{}} = result
    end
  end
end
