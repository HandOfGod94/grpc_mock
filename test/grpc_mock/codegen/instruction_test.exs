defmodule GrpcMock.DynamicCompiler.Codegen.InstructionTest do
  use ExUnit.Case, async: true
  alias GrpcMock.DynamicCompiler.Codegen
  doctest GrpcMock.DynamicCompiler.Codegen.Instruction
  import GrpcMock.DynamicCompiler.Codegen.Instruction

  describe "decode_instruction/2" do
    test "compile instruction - executes module function and modifies state" do
      codegen = %Codegen{}
      modules_fn = fn _ -> [{FooBar, "fizzbuzz"}] end
      {state, _} = decode_instruction(codegen, {:compile, modules_fn: modules_fn})
      assert [{FooBar, 'elixir_foobar', "fizzbuzz"}] = state.modules_generated
    end

    test "save - returns mfa for saving modules in mnesia" do
      codegen = %Codegen{}
      data_fn = fn _ -> ["foo", "bar"] end
      repo = FooRepo
      {_, mfa} = decode_instruction(codegen, {:save, {:modules_generated, repo: repo, data_fn: data_fn}})
      assert mfa == {FooRepo, :save_all, [["foo", "bar"]]}
    end

    test "publish code - returns mfa for loading code to all node" do
      codegen = %Codegen{}
      data_fn = fn _ -> ["foo", "bar"] end
      nodes = [:foo@machine]
      {_, mfa} = decode_instruction(codegen, {:publish, {:code, nodes: nodes, data_fn: data_fn}})
      assert mfa == {GrpcMock.Extension.Code, :remote_load, [["foo", "bar"], [:foo@machine]]}
    end

    test "publish pubsub - returns mfa for publishing message via phoneix pubsub to topic" do
      codegen = %Codegen{}
      message = %{status: :done}
      topic = "foo-topic"
      {_, mfa} = decode_instruction(codegen, {:publish, {:pubsub, topic: topic, message: message}})
      assert mfa == {PubSub, :broadcast!, [GrpcMock.PubSub, "foo-topic", %{status: :done}]}
    end
  end
end
