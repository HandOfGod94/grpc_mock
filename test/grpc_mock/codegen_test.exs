defmodule GrpcMock.CodegenTest do
  use ExUnit.Case, async: true
  doctest GrpcMock.Codegen
  alias GrpcMock.Codegen

  test "eex_compile/3 - sets eex compile instruction to codegen" do
    {instruction, _codegen} = %Codegen{} |> Codegen.eex_compile("foo.ex", foo: "bar", fizz: "buzz")
    assert instruction == [{:compile, template_name: "foo.ex", bindings: [foo: "bar", fizz: "buzz"]}]
  end

  test "protoc_compile/3 - sets protoc compile instruction to codegen" do
    {instruction, _codegen} = %Codegen{} |> Codegen.protoc_compile("/user/dir", "foo.proto")
    assert instruction == [{:compile, import_path: "/user/dir", file: "foo.proto"}]
  end

  test "save/1 - sets db save instruction" do
    dummy_mods = [{Foo, <<"foo">>, 'foo.gen.ex'}]
    {instruction, _codegen} = %Codegen{modules_generated: dummy_mods} |> Codegen.save()

    assert instruction == [
             [save: {GrpcMock.Codegen.Modules.Repo, :save_all, [[{:dyn_module, Foo, Foo, 'foo.gen.ex', "foo"}]]}]
           ]
  end
end
