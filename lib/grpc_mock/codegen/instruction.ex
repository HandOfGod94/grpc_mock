defmodule GrpcMock.Codegen.Instruction do
  alias GrpcMock.Extension.Code

  def decode_instruction(codegen, {:compile, modules_fn: module_fn}) do
    modules = module_fn.(codegen)
    codegen = codegen |> set_generated_modules(modules)
    {codegen, {Function, :identity, [codegen]}}
  end

  def decode_instruction(codegen, {:save, {:modules_generated, args}}) do
    records = args[:data_fn].(codegen)
    {codegen, {args[:repo], :save_all, [records]}}
  end

  def decode_instruction(codegen, {:publish, {:code, args}}) do
    data = args[:data_fn].(codegen)
    {codegen, {Code, :remote_load, [data, args[:nodes]]}}
  end

  @pubsub GrpcMock.PubSub
  def decode_instruction(codegen, {:publish, {:pubsub, args}}) do
    topic = args[:topic]
    message = args[:message]
    {codegen, {PubSub, :broadcast!, [@pubsub, topic, message]}}
  end

  def set_generated_modules(codegen, modules) do
    modules_generated =
      modules
      |> Enum.map(fn {mod, bin} -> {mod, Code.dynamic_module_filename(mod), bin} end)
      |> List.flatten()

    %{codegen | modules_generated: modules_generated ++ codegen.modules_generated}
  end
end
