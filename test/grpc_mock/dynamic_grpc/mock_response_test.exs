defmodule GrpcMock.DynamicServer.MockResponseTest do
  use ExUnit.Case, async: true
  doctest GrpcMock.DynamicServer.MockResponse
  alias GrpcMock.DynamicServer.MockResponse

  describe "changeset/2" do
    test "is invalid with empty mock_response" do
      changeset = MockResponse.changeset(%MockResponse{}, %{})
      refute changeset.valid?
    end

    test "is valid with required fields are present" do
      changeset =
        MockResponse.changeset(%MockResponse{}, %{
          method: "foo",
          return_type: "bar",
          data: Jason.encode!(%{hello: "world"})
        })

      assert changeset.valid?
    end
  end
end
