defmodule GrpcMock.DynamicServer.ServergenTest do
  use ExUnit.Case, async: true
  doctest GrpcMock.DynamicServer.Servergen
  import GrpcMock.Factory
  alias GrpcMock.DynamicServer.Servergen

  test "build_server_struct/2 - adds instruction to create server instance" do
    result = Servergen.build_server_struct(%Servergen{}, %{service: "GrpcMock.Foo"})
    assert result.instructions == [build_server_struct: [params: %{service: "GrpcMock.Foo"}]]
  end

  test "generate_implmentation/2 - adds instruction to generate server implmentation" do
    result = Servergen.generate_implmentation(%Servergen{}, template: "test-template.eex")
    assert result.instructions == [generate_implmentation: [template: "test-template.eex"]]
  end

  test "launch/2 - adds instruction to launch grpc servier" do
    result = Servergen.launch(%Servergen{})
    assert result.instructions == [{:launch}]
  end

  test "add_error/2 - adds error to servergen and sets valid? to false" do
    result = Servergen.add_error(%Servergen{}, {:error, :oops})
    refute result.valid?
    assert result.errors == [{:error, :oops}]
  end

  describe "changeset_error/2" do
    test "returns nil when there are no changeset error" do
      servergen = Servergen.add_error(%Servergen{}, {:error, :oops})
      assert Servergen.changeset_error(servergen) |> is_nil()
    end

    test "returns changeset when there are changeset error" do
      changeset_error = %Ecto.Changeset{errors: :foobar}
      servergen = Servergen.add_error(%Servergen{}, changeset_error)
      assert %Ecto.Changeset{} = Servergen.changeset_error(servergen)
    end
  end

  describe "apply_instruction/1" do
    test "applies all the instructions" do
      servergen = Servergen.build_server_struct(%Servergen{}, params_for(:server))
      assert %Servergen{valid?: true, server: _} = Servergen.apply_instruction(servergen)
    end

    test "doesn't apply instruction if it has errors" do
      servergen = Servergen.build_server_struct(%Servergen{}, params_for(:server, service: nil))
      assert %Servergen{valid?: false} = Servergen.apply_instruction(servergen)
    end
  end
end
