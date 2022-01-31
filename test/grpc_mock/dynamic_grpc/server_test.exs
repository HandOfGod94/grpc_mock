defmodule GrpcMock.DynamicServer.ServerTest do
  use ExUnit.Case, async: true
  doctest GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicServer.Server

  describe "changeset/2" do
    test "is invalid - when required params are missing" do
      changeset = Server.changeset(%Server{}, %{})
      refute changeset.valid?

      assert Enum.member?(
               changeset.errors,
               {:service, {"can't be blank", [validation: :required]}}
             )
    end

    test "is invalid - when required params missing for mock_response" do
      changeset =
        Server.changeset(%Server{}, %{
          service: "foo",
          port: 3000,
          mock_responses: [
            %{
              method: "foo"
            }
          ]
        })

      refute changeset.valid?
    end

    test "is valid with all the required values" do
      changeset =
        Server.changeset(%Server{}, %{
          service: "foo",
          port: 3000,
          mock_responses: [
            %{
              method: "foo",
              return_type: "bar",
              data: Jason.encode!(%{success: true})
            }
          ]
        })

      assert changeset.valid?
    end
  end

  describe "new/1" do
    test "returns server instance with valid values" do
      assert {:ok, %Server{}} =
               Server.new(%{
                 service: "foo",
                 port: 3000,
                 mock_responses: [
                   %{
                     method: "foo",
                     return_type: "bar",
                     data: Jason.encode!(%{success: true})
                   }
                 ]
               })
    end

    test "returns error with missing values" do
      assert {:error, changeset} = Server.new(%{})

      assert Enum.member?(
               changeset.errors,
               {:service, {"can't be blank", [validation: :required]}}
             )
    end
  end
end
