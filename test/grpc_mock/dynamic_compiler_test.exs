defmodule GrpcMock.DynamicCompilerTest do
  use ExUnit.Case
  doctest GrpcMock.DynamicCompiler
  alias GrpcMock.DynamicCompiler
  import GrpcMock.DynamicCompiler.Codegen.Modules.Store

  describe "available_modules/0" do
    test "returns all the key present in module table" do
      :mnesia.transaction(fn ->
        :mnesia.write(dyn_module(id: :foo, name: :foo))
        :mnesia.write(dyn_module(id: :bar, name: :bar))
      end)

      result = DynamicCompiler.available_modules()

      assert result == [:foo, :bar]
    end
  end
end
