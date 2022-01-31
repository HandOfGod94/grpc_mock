defmodule GrpcMock.Codegen do
  @moduledoc """
   Load multiple dynamically generated modules at runtime.
   It will hold all the required information for genrating dynamic code from `eex` or `proto`.any()

   A typical example of what information a `Codegen` struct is:

   ```elixir
   %__MODULE__{
     modules_generated: [
       {helloworld.Greeter, <<foobar>>, 'helloworld.gen.ex'}
     ]
     instructions: [
       {:compile, {:eex, template: "foo.ex", bindings: [foo: "bar", fizz: "buzz"]}}
       # or, for protoc
       # {:compile, {:protoc, import_path: "/dir/protos", file: "mozart.proto"}}
       {:publish, {:code, nodes: [:"foo@machine", :"bar@machine"]}, data_fn: &derive/1}
       {:publish, {:pubsub, topic: "sometopic", message: %{status: "success"}}}
       {:save {:modules_generated, repo: ModuleRepo, data_fn: &dervive/1}}
     ],
     status: :todo
   }
   ```
  """

  require Logger

  import GrpcMock.Codegen.Modules.Store
  alias GrpcMock.Extension.Code
  alias Phoenix.PubSub

  defstruct callback_mod: nil, fields: %{}, modules_generated: [], status: :todo, instructions: []

  @type args :: any()
  @type instruction :: {:compile, args()} | {:publish, args()} | {:save, args()}
  @type dynamic_module :: {module(), binary(), filename :: charlist()}
  @type status :: :todo | :in_progress | :done

  @type t :: %__MODULE__{
            callback_mod: module(),
            fields: [atom()],
            modules_generated: [dynamic_module()],
            instructions: [instruction()],
            status: status()
          }

  def cast(struct) do
    callback_mod = struct.__struct__
    %__MODULE__{
      callback_mod: callback_mod,
      fields: Map.from_struct(struct)
    }
  end

  def get_field(%__MODULE__{} = codegen, field), do: codegen.fields[field]

  def generate_modules_with(%__MODULE__{} = codegen, modules_fn) do
    compile = {:compile, modules_fn: modules_fn}
    codegen |> put_instruction(compile)
  end

  def save_with(%__MODULE__{} = codegen, repo) do
    data_fn = fn codegen ->
      codegen.modules_generated
      |> Enum.map(fn {mod, filename, bin} ->
        dyn_module(id: mod, name: mod, filename: filename, code_binary: bin)
      end)
    end

    instruction = {:save, {:modules_generated, repo: repo, data_fn: data_fn}}

    codegen |> put_instruction(instruction)
  end

  def broadcast_status(%__MODULE__{} = codegen, topic, message) do
    instruction = {:publish, {:pubsub, topic: topic, message: message}}
    codegen |> put_instruction(instruction)
  end

  def load_modules_on(%__MODULE__{} = codegen, nodes: nodes) do
    data_fn = fn codegen -> codegen.modules_generated end
    instruction = {:publish, {:code, nodes: nodes, data_fn: data_fn}}
    codegen |> put_instruction(instruction)
  end

  defp put_instruction(%__MODULE__{} = codegen, instruction) do
    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  def take_instructions(%__MODULE__{} = codegen), do: Enum.reverse(codegen.instructions)

  ## instructions applier

  @spec apply_instruction(t()) :: {any(), [dynamic_module()]}
  def apply_instruction(%__MODULE__{} = codegen) do
    codegen =
      codegen
      |> take_instructions()
      |> Enum.reduce(codegen, &do_apply(&2, &1))
      |> Map.put(:instructions, [])
      |> Map.put(:status, :done)

    {struct!(codegen.callback_mod, codegen.fields), codegen.modules_generated}
  end

  defp do_apply(state, instruction) do
    Logger.info("applying instruction: #{inspect(instruction)}")
    {state, {mod, fun, args}} = decode_instruction(state, instruction)
    apply(mod, fun, args)

    Logger.info("successfully applied")
    state
  end

  defp decode_instruction(codegen, {:compile, modules_fn: module_fn}) do
    modules = module_fn.(codegen)
    codegen = codegen |> set_generated_modules(modules)
    {codegen, {Function, :identity, [codegen]}}
  end

  defp decode_instruction(codegen, {:save, {:modules_generated, args}}) do
    records = args[:data_fn].(codegen)
    {codegen, {args[:repo], :save_all, [records]}}
  end

  defp decode_instruction(codegen, {:publish, {:code, args}}) do
    data = args[:data_fn].(codegen)
    {codegen, {Code, :remote_load, [data, args[:nodes]]}}
  end

  @pubsub GrpcMock.PubSub
  defp decode_instruction(codegen, {:publish, {:pubsub, args}}) do
    topic = args[:topic]
    message = args[:message]
    {codegen, {PubSub, :broadcast!, [@pubsub, topic, message]}}
  end

  def set_generated_modules(%__MODULE__{} = codegen, modules) do
    modules_generated =
      modules
      |> Enum.map(fn {mod, bin} -> {mod, Code.dynamic_module_filename(mod), bin} end)
      |> List.flatten()

    %{codegen | modules_generated: modules_generated ++ codegen.modules_generated}
  end
end
