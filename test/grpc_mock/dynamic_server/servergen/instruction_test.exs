defmodule GrpcMock.DynamicServer.Servergen.InstructionTest do
  use ExUnit.Case, async: false
  doctest GrpcMock.DynamicServer.Servergen.Instruction

  import GrpcMock.DynamicServer.Servergen.Instruction
  import GrpcMock.Factory

  alias GrpcMock.DynamicCompiler.ProtocLoader
  alias GrpcMock.DynamicServer.Servergen
  alias GrpcMock.DynamicServer.Server

  @template :code.priv_dir(:grpc_mock) |> Path.join("dynamic_server.eex")

  setup context do
    if file = context[:load_proto] do
      modules = load_proto(file)
      on_exit(fn -> unload_modules(modules) end)
    end

    :ok
  end

  describe "decode_instruction/2" do
    test "build_server_struct - creates instance with server set" do
      params = params_for(:server)
      {state, action} = decode_instruction(Servergen.new(), {:build_server_struct, params: params})

      assert action == {Function, :identity, [state]}
      assert state.valid?
      assert %Server{service: service} = state.server
      assert service == state.server.service
    end

    test "build_server_struct - adds error if server params are invalid" do
      params = params_for(:server, service: nil)
      {state, action} = decode_instruction(Servergen.new(), {:build_server_struct, params: params})

      assert action == {Function, :identity, [state]}
      refute state.valid?
      assert [%Ecto.Changeset{}] = state.errors
    end

    @tag load_proto: "helloworld.proto"
    test "generate_implmentation - sets endpoint for server" do
      server = build(:server)
      servergen = Servergen.new() |> Servergen.set_server(server)

      {state, action} = decode_instruction(servergen, {:generate_implmentation, template: @template})

      assert action == {Function, :identity, [state]}
      assert state.valid?
      assert state.endpoint == Greeter.Endpoint
    end

    test "generate_implementation - adds error when server body class is not loaded" do
      server = build(:server)
      servergen = Servergen.new() |> Servergen.set_server(server)

      {state, action} = decode_instruction(servergen, {:generate_implmentation, template: @template})

      assert action == {Function, :identity, [state]}
      refute state.valid?
      assert [{:generate_implmentation, _}] = state.errors
    end

    test "generate_implmentation - adds error when server info is not present" do
      servergen = Servergen.new()

      {state, action} = decode_instruction(servergen, {:generate_implmentation, template: @template})

      assert action == {Function, :identity, [state]}
      refute state.valid?
      assert [{:generate_implmentation, _}] = state.errors
    end

    test "generate_implmentation - adds error when template is not present" do
      server = build(:server)
      servergen = Servergen.new() |> Servergen.set_server(server)

      {state, action} = decode_instruction(servergen, {:generate_implmentation, template: nil})

      assert action == {Function, :identity, [state]}
      refute state.valid?
      assert [{:generate_implmentation, _}] = state.errors
    end

    test "launch - sets action to launch grpc server" do
      servergen = %Servergen{server: :foo, endpoint: :bar}
      {_, action} = decode_instruction(servergen, {:launch})

      assert action == {Server, :start, [servergen.server, servergen.endpoint]}
    end
  end

  defp load_proto(proto_file) do
    import_path = Path.join([File.cwd!(), "test", "support", "fixtures"])
    {:ok, modules} = ProtocLoader.load_modules(import_path, proto_file)
    modules.modules_generated
  end

  defp unload_modules(modules) do
    for {mod, _, _} <- modules do
      :code.purge(mod)
    end
  end
end
