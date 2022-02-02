defmodule GrpcMock.DynamicServer.Servergen.ServerStore do
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  @table :grpc_server

  defrecord(
    @table,
    @table,
    id: nil,
    service: "",
    port: -1,
    mock_responses: []
  )

  @impl Mnesiac.Store
  def store_options do
    [
      record_name: @table,
      attributes: grpc_server(grpc_server()) |> Keyword.keys(),
      index: [],
      ram_copies: [node()]
    ]
  end
end
