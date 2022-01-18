defmodule GrpcMock.DynamicGrpcTest do
  use ExUnit.Case, async: false
  doctest GrpcMock.DynamicGrpc

  alias GrpcMock.DynamicGrpc
  alias GrpcMock.DynamicGrpc.Server

  @registry GrpcMock.ServerRegistry

  describe "list_all_servers/0" do
    test "returns empty list when there are no entries" do
      res = DynamicGrpc.list_all_servers()
      assert res == []
    end

    test "returns value when there are entries in registry" do
      {:ok, %Server{id: id} = server} =
        Server.new(%{
          service: "Service",
          port: 3001,
          mock_responses: [
            %{
              method: "transfer",
              return_type: "TransactionResponse",
              data: %{success: false}
            }
          ]
        })

        # register with process
      name = {:via, Registry, {@registry, id, server}}
      {:ok, pid} = Agent.start_link(fn -> %{} end, name: name)

      res = DynamicGrpc.list_all_servers()
      assert [%{pid: ^pid, server: ^server}] = res
    end
  end

  describe "fetch_server_info/1" do
    test "should return nil when id is not present" do
      res = DynamicGrpc.fetch_server("foo")
      assert res == nil
    end

     test "should return server info if id present" do
      {:ok, %Server{id: id} = server} =
        Server.new(%{
          service: "Service",
          port: 3001,
          mock_responses: [
            %{
              method: "transfer",
              return_type: "TransactionResponse",
              data: %{success: false}
            }
          ]
        })

      # register with process
      name = {:via, Registry, {@registry, server.id, server}}
      {:ok, pid} = Agent.start_link(fn -> %{} end, name: name)

      assert {^pid, %Server{id: ^id}} = DynamicGrpc.fetch_server(id)
     end
  end
end
