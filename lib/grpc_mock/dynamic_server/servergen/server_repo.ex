defmodule GrpcMock.DynamicServer.Servergen.ServerRepo do
  @table :grpc_server

  def all_dirty do
    :mnesia.dirty_all_keys(@table)
  end

  def one(key) do
    :mnesia.transaction(fn ->
      :mnesia.read(@table, key)
      |> Enum.at(0)
    end)
  end

  def save(server_record) do
    :mnesia.transaction(fn ->
      :mnesia.write(server_record)
    end)
  end

  def save_all(server_records) when is_list(server_records) do
    :mnesia.transaction(fn ->
      Enum.each(server_records, &:mnesia.write/1)
    end)
  end
end
