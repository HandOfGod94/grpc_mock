defmodule GrpcMock.DynamicGrpc.GrpcGenServer do
  use GenServer, restart: :transient

  @moduledoc """
  Very dumb genserver to add additional behaviors over GRPC.supervisor.

  It adds:
  1. named registration, so we can retrive pid and the server info on UI
  2. make restart :transient, so in case if supervisor crashes it starts again, but if it stops, the server
  will die as well.
  """

  ## client apis

  def start_link({server, _} = opts) do
    GenServer.start_link(__MODULE__, opts,
      name: {:via, Registry, {GrpcMock.ServerRegistry, server.id, server}}
    )
  end

  ## server apis

  def init({server, endpoint}) do
    GRPC.Server.Supervisor.start_link({endpoint, server.port})
  end
end