defmodule GrpcMock.DynamicGrpc.Server do
  defmodule ValidationError do
    defexception [:field, :value]

    def message(validation_error) do
      "invalid value: #{inspect(validation_error.value)} provided for field: #{validation_error.field}"
    end
  end

  defmodule Response do
    defstruct [:method_name, :return_type, data: %{}, headers: %{}, trailers: %{}]

    def new(params) do
      {:ok, struct(__MODULE__, params)}
    end
  end

  @enforce_keys [:service, :port]
  defstruct [:pid, :service, :port, status: :down, mocks: []]

  def new(%{status: status}) when status not in [:up, :down],
    do: {:error, %ValidationError{field: "status", value: status}}

  def new(%{port: port}) when not is_number(port),
    do: {:error, %ValidationError{field: "port", value: port}}

  def new(%{mocks: mocks}) when not is_list(mocks),
    do: {:error, %ValidationError{field: "mocks", value: mocks}}

  def new(params) do
    {:ok, struct(__MODULE__, params)}
  end
end
