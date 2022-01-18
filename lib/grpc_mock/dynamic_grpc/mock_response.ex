defmodule GrpcMock.DynamicGrpc.MockResponse do
  use Ecto.Schema
  import Ecto.Changeset

  @required [:method, :return_type, :data]
  @optional [:headers, :trailers]

  embedded_schema do
    field :method, :string
    field :return_type, :string
    field :data, :map, default: %{}
    field :headers, :map, default: %{}
    field :trailers, :map, default: %{}
  end

  def changeset(mock_response, params \\ %{}) do
    mock_response
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
  end
end
