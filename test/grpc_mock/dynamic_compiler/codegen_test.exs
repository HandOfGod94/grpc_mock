defmodule GrpcMock.DynamicCompiler.CodegenTest do
  use ExUnit.Case, async: true
  doctest GrpcMock.DynamicCompiler.Codegen
  alias GrpcMock.DynamicCompiler.Codegen

  test "generate_modules_with/2 - adds instruction to generate modules based on lambda provided" do
    modules_fn = fn _codegen -> [:foo, :bar] end
    result = Codegen.generate_modules_with(%Codegen{}, modules_fn)
    assert result.instructions == [compile: [generator_fn: modules_fn]]
  end

  test "save_with/2 - adds instruction to save generated modules with given repo" do
    result = Codegen.save_with(%Codegen{}, :foo_repo)
    assert [save: {:modules_generated, [repo: :foo_repo, records_fn: _]}] = result.instructions
  end

  test "broadcast_status/2 - adds instruction to publish loading status on a pubsub topic" do
    result = Codegen.broadcast_status(%Codegen{}, "test-topic", %{status: :done})
    assert result.instructions == [publish: {:pubsub, [topic: "test-topic", message: %{status: :done}]}]
  end

  test "load_modules_on/2 - adds instruction to publish modules code on erlang nodes" do
    result = Codegen.load_modules_on(%Codegen{}, nodes: [:foo@machine])
    assert result.instructions == [publish: {:code, [nodes: [:foo@machine]]}]
  end

  test "add_error/2 - sets valid? to false and adds errors to codegen struct" do
    result = Codegen.add_error(%Codegen{}, {:error, :something_went_wrong})
    refute result.valid?
    assert result.errors == [{:error, :something_went_wrong}]
  end
end
