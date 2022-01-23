defmodule GrpcMock.PbDynamicCompiler.ModuleStore do
  @moduledoc """
  Mnesia store, to hold all the loaded modules available.
  """
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  defrecord(
    :module,
    :module,
    id: nil,
    name: nil
  )

  def store_options do
    [
      record_name: :module,
      attributes: module(module()) |> Keyword.keys(),
      index: [],
      ram_copies: [node()]
    ]
  end
end
