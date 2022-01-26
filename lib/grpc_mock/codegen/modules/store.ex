defmodule GrpcMock.Codegen.Modules.Store do
  @moduledoc """
  Mnesia store, to hold all the loaded modules available.
  """
  use Mnesiac.Store
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

  @impl Mnesiac.Store
  def store_options do
    [
      record_name: @table,
      attributes: dyn_module(dyn_module()) |> Keyword.keys(),
      index: [:name],
      ram_copies: [node()]
    ]
  end
end
