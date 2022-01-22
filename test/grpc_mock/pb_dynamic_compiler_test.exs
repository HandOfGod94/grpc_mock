defmodule GrpcMock.PbDynamicCompilerTest do
  use ExUnit.Case
  doctest GrpcMock.PbDynamicCompiler
  alias GrpcMock.PbDynamicCompiler

  setup do
    start_supervised(PbDynamicCompiler)
    import_path = Path.join([__DIR__, "..", "support", "fixtures"])

    on_exit(fn -> GenServer.stop(PbDynamicCompiler) end)

    %{import_path: import_path}
  end

  describe "codegen/2" do
    test "generates elixir file for provided proto file", %{import_path: import_path} do
      proto_file = "helloworld.proto"
      PbDynamicCompiler.codegen(import_path, proto_file)
      result = :sys.get_state(PbDynamicCompiler)

      assert result ==
               MapSet.new([
                 GprcMock.Protos.Helloworld.Greeter.Service,
                 GprcMock.Protos.Helloworld.Greeter.Stub,
                 GprcMock.Protos.Helloworld.HelloReply,
                 GprcMock.Protos.Helloworld.HelloRequest
               ])
    end

    test "compiled_modules state remains unchanged when import_path is incorrect" do
      proto_file = "helloworld.proto"
      PbDynamicCompiler.codegen("/foo/bar", proto_file)
      result = :sys.get_state(PbDynamicCompiler)

      assert result == MapSet.new()
    end

    test "compiled_modules state remains unchanged when proto file is invalid",
         %{import_path: import_path} do
      proto_file = "foo.bar"
      PbDynamicCompiler.codegen(import_path, proto_file)
      result = :sys.get_state(PbDynamicCompiler)

      assert result == MapSet.new()
    end
  end

  describe "available_modules/0" do
    test "returns all the loaded modules", %{import_path: import_path} do
      proto_file = "helloworld.proto"
      PbDynamicCompiler.codegen(import_path, proto_file)

      # wait till cast call completes
      :sys.get_state(PbDynamicCompiler)

      result = PbDynamicCompiler.available_modules()

      assert result ==
               MapSet.new([
                 GprcMock.Protos.Helloworld.Greeter.Service,
                 GprcMock.Protos.Helloworld.Greeter.Stub,
                 GprcMock.Protos.Helloworld.HelloReply,
                 GprcMock.Protos.Helloworld.HelloRequest
               ])
    end
  end
end
