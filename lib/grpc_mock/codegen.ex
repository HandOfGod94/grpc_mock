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
  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo
  alias GrpcMock.Codegen.ProtocCompiler
  alias GrpcMock.Codegen.EExCompiler
  alias GrpcMock.Extension.Code
  alias Phoenix.PubSub

  defstruct modules_generated: [], status: :todo, instructions: []

  @type args :: any()
  @type instruction :: {:compile, args()} | {:publish, args()} | {:save, args()}
  @type dynamic_module :: {module(), binary(), filename :: charlist()}
  @type status :: :todo | :in_progress | :done

  @opaque t :: %__MODULE__{
            modules_generated: [dynamic_module()],
            instructions: [instruction()],
            status: status()
          }

  @spec modules_generated(t()) :: [dynamic_module()]
  def modules_generated(%__MODULE__{modules_generated: modules}), do: modules

  @spec eex_compile(t(), String.t(), keyword()) :: t()
  def eex_compile(%__MODULE__{} = codegen, template, bindings) do
    compile = {:compile, {:eex, template: template, bindings: bindings}}
    compile = put_instruction(codegen, compile)

    compile
    |> save()
    |> broadcast_status()
    |> load_modules_on_all_nodes()
  end

  @spec protoc_compile(t(), String.t(), String.t()) :: t()
  def protoc_compile(%__MODULE__{} = codegen, import_path, file) do
    compile = {:compile, {:protoc, import_path: import_path, file: file}}
    compile = put_instruction(codegen, compile)

    compile
    |> save()
    |> broadcast_status()
    |> load_modules_on_all_nodes()
  end

  defp save(%__MODULE__{} = codegen) do
    data_fn = fn codegen ->
      codegen.modules_generated
      |> Enum.map(fn {mod, filename, bin} ->
        dyn_module(id: mod, name: mod, filename: filename, code_binary: bin)
      end)
    end

    instruction = {:save, {:modules_generated, repo: ModuleRepo, data_fn: data_fn}}

    codegen |> put_instruction(instruction)
  end

  @topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)
  defp broadcast_status(%__MODULE__{} = codegen) do
    status_message = fn codegen -> %{status: codegen.status} end
    instruction = {:publish, {:pubsub, topic: @topic, data_fn: status_message}}
    codegen |> put_instruction(instruction)
  end

  defp load_modules_on_all_nodes(%__MODULE__{} = codegen), do: load_modules_on_nodes(codegen, Node.list())

  defp load_modules_on_nodes(%__MODULE__{} = codegen, nodes) do
    data_fn = fn codegen -> codegen.modules_generated end
    instruction = {:publish, {:code, nodes: nodes, data_fn: data_fn}}
    codegen |> put_instruction(instruction)
  end

  defp put_instruction(%__MODULE__{} = codegen, instruction) do
    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  def take_instructions(%__MODULE__{} = codegen), do: Enum.reverse(codegen.instructions)

  ## instructions applier

  @spec apply_instruction(t()) :: t()
  def apply_instruction(%__MODULE__{} = codegen) do
    codegen
    |> take_instructions()
    |> Enum.reduce(codegen, &do_apply(&2, &1))
    |> Map.put(:instructions, [])
    |> Map.put(:status, :done)
  end

  defp do_apply(state, instruction) do
    Logger.info("applying instruction: #{inspect(instruction)}")
    {state, {mod, fun, args}} = decode_instruction(state, instruction)
    apply(mod, fun, args)

    Logger.info("successfully applied")
    state
  end

  defp decode_instruction(codegen, {:compile, {:eex, args}}) do
    modules = EExCompiler.compile(args[:template], args[:bindings])
    codegen = codegen |> set_generated_modules(modules)
    {codegen, {Function, :identity, [codegen]}}
  end

  defp decode_instruction(codegen, {:compile, {:protoc, args}}) do
    modules = ProtocCompiler.compile(args[:import_path], args[:file])
    codegen = codegen |> set_generated_modules(modules)
    {codegen, {Function, :identity, [codegen]}}
  end

  defp decode_instruction(codegen, {:save, {:modules_generated, args}}) do
    records = apply(args[:data_fn], [codegen])
    {codegen, {args[:repo], :save_all, [records]}}
  end

  defp decode_instruction(codegen, {:publish, {:code, args}}) do
    data = apply(args[:data_fn], [codegen])
    {codegen, {Code, :remote_load, [data, args[:nodes]]}}
  end

  @pubsub GrpcMock.PubSub
  defp decode_instruction(codegen, {:publish, {:pubsub, args}}) do
    topic = args[:topic]
    message = apply(args[:data_fn], [codegen])
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
