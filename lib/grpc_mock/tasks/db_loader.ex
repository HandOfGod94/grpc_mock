defmodule GrpcMock.Tasks.DbLoader do
  require Logger

  import GrpcMock.Codegen.Modules.Store

  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo

  @table :dyn_module

  def load_modules do
    Logger.info("loading modules from mnesia")
    :mnesia.wait_for_tables([@table], 10_000)

    for key <- ModuleRepo.all_dirty() do
      {:atomic, record} = ModuleRepo.one(key)

      {name, filename, code_binary} =
        {dyn_module(record, :name), dyn_module(record, :filename), dyn_module(record, :code_binary)}

      :code.load_binary(name, filename, code_binary)
    end

    Logger.info("successfully loaded modules from mnesia")
  end
end
