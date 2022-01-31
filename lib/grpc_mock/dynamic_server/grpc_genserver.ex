defmodule GrpcMock.DynamicServer.GrpcGenServer do
  use GenServer, restart: :transient
  alias GrpcMock.DynamicServer.Server
  alias Registry

  @moduledoc """
  Very dumb genserver to add additional behaviors over GRPC.supervisor.

  It adds:
  1. named registration, so we can retrieve pid and the server info on UI
  2. make restart :transient, so in case if supervisor crashes it starts again, but if it stops, the server
  will die as well.
  """

  ## client apis

  @spec start_link({Server.t(), atom()}) :: GenServer.on_start()
  def start_link({server, _} = opts) do
    GenServer.start_link(__MODULE__, opts, name: {:via, Registry, {GrpcMock.ServerRegistry, server.id, server}})
  end

  ## server apis

  @impl GenServer
  def init({server, endpoint}) do
    GRPC.Server.Supervisor.start_link({endpoint, server.port})
  end
end
