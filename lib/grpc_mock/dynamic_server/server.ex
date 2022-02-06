defmodule GrpcMock.DynamicServer.Server do
  use Ecto.Schema
  import Ecto.Changeset
  alias GrpcMock.DynamicServer.MockResponse
  alias GrpcMock.DynamicSupervisor

  @required [:service, :port]
  @optional [:id]
  embedded_schema do
    field(:service, :string)
    field(:port, :integer)
    embeds_many(:mock_responses, MockResponse)
  end

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id() | nil,
          service: String.t() | nil,
          port: number() | nil,
          mock_responses: list(MockResponse.t())
        }

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(server, params \\ %{}) do
    server
    |> cast(params, @required ++ @optional)
    |> cast_embed(:mock_responses, required: true)
    |> validate_required(@required)
  end

  @spec new(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(params) do
    %__MODULE__{}
    |> Map.put(:id, Nanoid.generate())
    |> changeset(params)
    |> apply_action(:insert)
  end

  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(server, params) do
    server
    |> changeset(params)
    |> apply_action(:update)
  end

  @spec start(t(), module()) :: Supervisor.on_start_child()
  def start(server, endpoint), do: DynamicSupervisor.start_server(server, endpoint)
end
