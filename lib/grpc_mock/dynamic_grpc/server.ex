defmodule GrpcMock.DynamicGrpc.Server do
  use Ecto.Schema
  import Ecto.Changeset
  alias GrpcMock.DynamicGrpc.MockResponse

  @required [:service, :port]
  @optional [:id, :pid, :status]

  embedded_schema do
    field :pid, :string
    field :service, :string
    field :port, :integer
    field :status, :string, default: "down"
    embeds_many :mock_responses, MockResponse
  end

  def changeset(server, params\\%{}) do
    server
    |> cast(params, @required ++ @optional)
    |> cast_embed(:mock_responses, required: true)
    |> validate_required(@required)
    |> validate_inclusion(:status, ["up", "down"])
  end

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
