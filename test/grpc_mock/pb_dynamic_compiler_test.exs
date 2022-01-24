defmodule GrpcMock.PbDynamicCompilerTest do
  use ExUnit.Case, async: false
  doctest GrpcMock.PbDynamicCompiler
  alias GrpcMock.PbDynamicCompiler
  import GrpcMock.PbDynamicCompiler.ModuleStore

  setup do
    Mnesiac.init_mnesia(node())

    on_exit(fn ->
      :mnesia.transaction(fn -> :mnesia.clear_table(:module) end)
    end)

    :ok
  end

  describe "available_modules/0" do
    test "returns all the key present in module table" do
      :mnesia.transaction(fn ->
        :mnesia.write(module(id: :foo, name: :foo))
        :mnesia.write(module(id: :bar, name: :bar))
      end)

      result = PbDynamicCompiler.available_modules()

      assert result == [:foo, :bar]
    end
  end
end
