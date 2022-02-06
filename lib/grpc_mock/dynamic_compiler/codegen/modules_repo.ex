defmodule GrpcMock.DynamicCompiler.Codegen.ModulesRepo do
  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore

  @table :dyn_module

  @spec all_dirty() :: [term()]
  def all_dirty do
    :mnesia.dirty_all_keys(@table)
  end

  @spec one(atom()) :: {:atomic, term()} | {:aborted, reason :: term()}
  def one(key) do
    :mnesia.transaction(fn ->
      :mnesia.read(@table, key)
      |> Enum.at(0)
    end)
  end

  @spec save(ModulesStore.dyn_module()) :: {:atomic, term()} | {:aborted, reason :: term()}
  def save(module_record) do
    :mnesia.transaction(fn ->
      :mnesia.write(module_record)
    end)
  end

  @spec save_all([ModulesStore.dyn_module()]) :: {:atomic, term()} | {:aborted, reason :: term()}
  def save_all(module_records) when is_list(module_records) do
    :mnesia.transaction(fn ->
      Enum.each(module_records, &:mnesia.write/1)
    end)
  end
end
