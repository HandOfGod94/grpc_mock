defmodule GrpcMock.DynamicCompiler.Codegen.Instruction do
  alias GrpcMock.Extension.Code
  alias GrpcMock.DynamicCompiler.Codegen.ModulesStore
  alias GrpcMock.DynamicCompiler.Codegen
  alias Phoenix.PubSub

  @type compiled_modules :: {module(), binary()}
  @type generator_fn :: (Codegen.t() -> [compiled_modules()])
  @type records_fn :: (Codegen.t() -> [ModulesStore.dyn_module()])

  @type compile_instruction :: {:compile, generator_fn: generator_fn()}
  @type save_instruction :: {:save, {:modules_generated, repo: atom(), records_fn: records_fn()}}
  @type publish_instruction :: {:publish, {:pubsub, topic: String.t(), message: any()}}

  @type instruction :: compile_instruction() | save_instruction() | publish_instruction()

  @type args :: [any()]
  @type function_name :: atom()
  @type mfa_tuple :: {module(), function_name(), args()}

  @spec decode_instruction(Codegen.t(), instruction()) :: {Codegen.t(), mfa_tuple()}
  def decode_instruction(codegen, {:compile, generator_fn: generator_fn}) do
    codegen =
      case generator_fn.(codegen) do
        {:ok, modules} -> set_generated_modules(codegen, modules)
        {:error, error} -> Codegen.add_error(codegen, {:compile, error})
      end

    {codegen, noop_mfa(codegen)}
  end

  def decode_instruction(codegen, {:save, {:modules_generated, repo: repo, records_fn: records_fn}}) do
    records = records_fn.(codegen)
    {codegen, {repo, :save_all, [records]}}
  end

  @pubsub GrpcMock.PubSub
  def decode_instruction(codegen, {:publish, {:pubsub, topic: topic, message: message}}) do
    {codegen, {PubSub, :broadcast!, [@pubsub, topic, message]}}
  end

  defp set_generated_modules(codegen, modules) do
    modules_generated =
      modules
      |> Enum.map(fn {mod, bin} -> {mod, Code.dynamic_module_filename(mod), bin} end)
      |> List.flatten()

    %{codegen | modules_generated: modules_generated ++ codegen.modules_generated}
  end

  defp noop_mfa(value), do: {Function, :identity, [value]}
end
