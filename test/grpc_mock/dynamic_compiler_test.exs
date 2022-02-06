defmodule GrpcMock.DynamicCompilerTest do
  use ExUnit.Case
  doctest GrpcMock.DynamicCompiler
  alias GrpcMock.DynamicCompiler
  import GrpcMock.DynamicCompiler.Codegen.ModulesStore

  setup do
    :mnesia.create_table(:dyn_module, store_options())
    :mnesia.wait_for_tables([:dyn_module], 10_000)
    :ok
  end

  describe "available_modules/0" do
    test "returns all the key present in module table" do
      :mnesia.dirty_write(dyn_module(id: :foo, name: :foo))
      :mnesia.dirty_write(dyn_module(id: :bar, name: :bar))

      result = DynamicCompiler.available_modules() |> MapSet.new()

      assert MapSet.member?(result, :foo)
      assert MapSet.member?(result, :bar)
    end
  end
end
