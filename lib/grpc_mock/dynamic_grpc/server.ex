defmodule GrpcMock.DynamicGrpc.Server do
  use Ecto.Schema
  import Ecto.Changeset
  alias GrpcMock.DynamicGrpc.MockResponse

  @required [:service, :port]
  @optional [:id]

  embedded_schema do
    field :service, :string
    field :port, :integer
    embeds_many :mock_responses, MockResponse
  end

  @type t :: %__MODULE__{
    id: String.t() | nil,
    service: String.t(),
    port: Integer.t(),
    mock_responses: MockResponse.t()
  }

  def changeset(server, params\\%{}) do
    server
    |> cast(params, @required ++ @optional)
    |> cast_embed(:mock_responses, required: true)
    |> validate_required(@required)
  end

  @spec new(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(params) do
    params = Map.put_new(params, :id, Nanoid.generate())

    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  def update(server, params) do
    server
    |> changeset(params)
    |> apply_action(:update)
  end
end
