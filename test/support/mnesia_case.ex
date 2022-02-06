defmodule GrpcMock.MnesiaCase do
  use ExUnit.CaseTemplate
  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore

  @mnesia_table :dyn_module

  setup do
    :mnesia.create_table(@mnesia_table, ModulesStore.store_options())
    :mnesia.wait_for_tables([:dyn_module], 10_000)

    on_exit(fn ->
      :mnesia.transaction(fn -> :mnesia.clear_table(@mnesia_table) end)
    end)

    :ok
  end
end
