defmodule GrpcMock.DynamicCompiler.Codegen.ModulesStore do
  @moduledoc """
  Mnesia store, to hold all the loaded modules available.
  """
  import Record, only: [defrecord: 3]

  @table :dyn_module

  defrecord(
    @table,
    @table,
    id: nil,
    name: nil,
    filename: nil,
    code_binary: nil
  )

  @type dyn_module ::
          record(
            :dyn_module,
            id: atom(),
            name: atom(),
            filename: charlist(),
            code_binary: binary()
          )

  @spec store_options() :: Keyword.t()
  def store_options do
    [
      record_name: @table,
      attributes: dyn_module(dyn_module()) |> Keyword.keys(),
      index: [],
      ram_copies: [node()]
    ]
  end
end
