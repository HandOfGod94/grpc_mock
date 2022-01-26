defmodule GrpcMock.Codegen.Modules.Repo do
  @table :dyn_module

  def all_dirty do
    :mnesia.dirty_all_keys(@table)
  end

  def one(key) do
    :mnesia.transaction(fn ->
      :mnesia.read(@table, key)
      |> Enum.at(0)
    end)
  end

  def save(module_record) do
    :mnesia.transaction(fn ->
      :mnesia.write(module_record)
    end)
  end

  def save_all(module_records) when is_list(module_records) do
    :mnesia.transaction(fn ->
      Enum.each(module_records, &:mnesia.write/1)
    end)
  end
end
