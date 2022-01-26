defmodule GrpcMock.Factory do
  # credo:disable-for-this-file

  use ExMachina.Ecto

  alias GrpcMock.DynamicGrpc.MockResponse
  alias GrpcMock.DynamicGrpc.Server

  def mock_response_factory do
    %MockResponse{
      method: "say_hello",
      return_type: "GrpcMock.Protos.Helloworld.HelloReply",
      data: Jason.encode!(%{message: "helloworld"})
    }
  end

  def server_factory do
    %Server{
      id: "starwars-server",
      service: "GrpcMock.Protos.Helloworld.Greeter.Service",
      port: 3001,
      mock_responses: [build(:mock_response)]
    }
  end
end
