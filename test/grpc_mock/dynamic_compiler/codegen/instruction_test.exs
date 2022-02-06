defmodule GrpcMock.DynamicCompiler.Codegen.InstructionTest do
  use ExUnit.Case, async: true
  alias Phoenix.PubSub
  alias GrpcMock.DynamicCompiler.Codegen
  doctest GrpcMock.DynamicCompiler.Codegen.Instruction
  import GrpcMock.DynamicCompiler.Codegen.Instruction

  describe "decode_instruction/2" do
    test "compile instruction - executes module function and modifies state" do
      codegen = %Codegen{}
      generator_fn = fn _ -> {:ok, [{FooBar, "fizzbuzz"}]} end
      {state, _} = decode_instruction(codegen, {:compile, generator_fn: generator_fn})
      assert [{FooBar, 'elixir_foobar', "fizzbuzz"}] = state.modules_generated
    end

    test "save - returns mfa for saving modules in mnesia" do
      codegen = %Codegen{}
      records_fn = fn _ -> ["foo", "bar"] end
      repo = FooRepo
      {_, mfa} = decode_instruction(codegen, {:save, {:modules_generated, repo: repo, records_fn: records_fn}})
      assert mfa == {FooRepo, :save_all, [["foo", "bar"]]}
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
