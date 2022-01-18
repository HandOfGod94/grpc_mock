defmodule GrpcMock.DynamicGrpc.Mock do
  defmodule Response do
    # data, headers and trailers needs to be json encoded string
    defstruct [:method_name, :return_type, data: %{}, headers: %{}, trailers: %{}]
  end

  defstruct [:service, responses: [%{}]]
end
