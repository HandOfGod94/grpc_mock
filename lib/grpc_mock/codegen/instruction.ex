defmodule GrpcMock.Codegen.Instruction do
  alias GrpcMock.Extension.Code
  alias GrpcMock.Codegen
  alias Phoenix.PubSub

  @type compiled_modules :: {module(), binary()}
  @type modules_fn :: (Codegen.t() -> [compiled_modules()])
  @type data_fn :: (Codegen.t() -> [any()])

  @type compile_instruction :: {:compile, modules_fn: modules_fn()}
  @type save_instruction :: {:save, {:modules_generated, repo: atom(), data_fn: data_fn()}}
  @type publish_instruction ::
          {:publish, {:pubsub, topic: String.t(), message: any()}}
          | {:publish, {:code, nodes: list(atom()), data_fn: data_fn()}}

  @type instruction :: compile_instruction() | save_instruction() | publish_instruction()

  @type args :: [any()]
  @type function_name :: atom()
  @type mfa_tuple :: {module(), function_name(), args()}

  @spec decode_instruction(Codegen.t(), instruction()) :: {Codegen.t(), mfa_tuple()}
  def decode_instruction(codegen, {:compile, modules_fn: modules_fn}) do
    codegen =
      case modules_fn.(codegen) do
        {:ok, modules} ->
          codegen |> set_generated_modules(modules)

        {:error, error} ->
          codegen |> Codegen.add_error({:compile, error})
      end

    {codegen, {Function, :identity, [codegen]}}
  end

  def decode_instruction(codegen, {:save, {:modules_generated, repo: repo, data_fn: data_fn}}) do
    records = data_fn.(codegen)
    {codegen, {repo, :save_all, [records]}}
  end

  def decode_instruction(codegen, {:publish, {:code, nodes: nodes, data_fn: data_fn}}) do
    data = data_fn.(codegen)
    {codegen, {Code, :remote_load, [data, nodes]}}
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
end
