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
       {:compile, EExCompiler, template: "foo.ex", bindings: [foo: "bar", fizz: "buzz"]}
       # or, for protoc
       # {:compile, ProtocCompiler, import_path: "/dir/protos", file: "mozart.proto"}
       {:publish, RemoteNode, [:"foo@machine", :"bar@machine"]},
       {:publish, Pubsub, [@server, @topic, %{message: "dummy"}]},
       {:save_all, ModuleRepo, [record()]}
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

  defstruct modules_generated: [], status: :todo, instructions: [], errors: []

  @typep ma :: {module(), args :: [any()]}

  @type eex_compile_args :: [template_name: String.t(), binding: keyword()]
  @type protoc_compile_args :: [import_path: String.t(), file: String.t()]

  @type instruction ::
          {:compile, ma()}
          | {:publish, ma()}
          | {:save, ma()}
          | {function :: atom(), ma()}

  @type status :: :todo | :in_progress | :done | :failed
  @type dynamic_module :: {module(), binary(), filename :: charlist()}

  @opaque t :: %__MODULE__{
            modules_generated: [dynamic_module()],
            instructions: [instruction()],
            status: status()
          }

  @spec modules_generated(t()) :: [dynamic_module()]
  def modules_generated(%__MODULE__{modules_generated: modules}), do: modules

  @spec eex_compile(t(), String.t(), keyword()) :: t()
  def eex_compile(%__MODULE__{} = codegen, template, bindings) do
    instruction = {:compile, EExCompiler, [template, bindings]}

    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  @spec protoc_compile(t(), String.t(), String.t()) :: t()
  def protoc_compile(%__MODULE__{} = codegen, import_path, file) do
    instruction = {:compile, ProtocCompiler, [import_path, file]}

    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  @spec save(t()) :: t()
  def save(%__MODULE__{} = codegen) do
    records =
      codegen.modules_generated
      |> Enum.map(fn {mod, filename, bin} ->
        dyn_module(id: mod, name: mod, filename: filename, code_binary: bin)
      end)

    instruction = {:save_all, ModuleRepo, [records]}

    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  @pubsub GrpcMock.PubSub
  @topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)
  def broadcast_status(%__MODULE__{} = codegen) do
    instruction = {:broadcast!, PubSub, [@pubsub, @topic, %{status: codegen.status}]}

    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  @spec load_modules_on_all_nodes(t()) :: t()
  def load_modules_on_all_nodes(%__MODULE__{} = codegen), do: load_modules_on_nodes(codegen, Node.list())

  @spec load_modules_on_nodes(t(), [node()]) :: t()
  def load_modules_on_nodes(%__MODULE__{} = codegen, nodes) do
    publish_instructions =
      codegen.modules_generated
      |> Enum.map(fn {mod, bin, filename} ->
        {:remote_load, Code, [mod, filename, bin, nodes]}
      end)

    %{codegen | instructions: [publish_instructions | codegen.instructions]}
  end

  @spec apply_instruction(t()) :: t()
  def apply_instruction(%__MODULE__{} = codegen) do
    codegen =
      codegen.instructions
      |> Enum.reverse()
      |> Enum.reduce_while(codegen, fn instr, codegen ->
        codegen = apply_instruction(codegen, instr)

        case codegen do
          %{status: :in_progress} -> {:cont, codegen}
          _ -> {:halt, codegen}
        end
      end)
      |> Map.put(:instructions, [])

    if codegen.status != :failed do
      %{codegen | status: :done}
    else
      codegen
    end
  end

  def apply_instruction(%__MODULE__{} = codegen, instruction) do
    Logger.info("Applying instruction: #{inspect(instruction)}")

    try do
      case instruction do
        {:compile, mod, args} ->
          generated_modules = apply(mod, :compile, args)
          set_generated_modules(codegen, generated_modules)

        {fun, mod, args} ->
          apply(mod, fun, args)
          %{codegen | status: :in_progress}
      end
    rescue
      error -> %{codegen | status: :failed, errors: [error | codegen.errors]}
    end
  end

  defp set_generated_modules(%__MODULE__{} = codegen, modules) do
    modules_generated =
      modules
      |> Enum.map(fn {mod, bin} -> {mod, Code.dynamic_module_filename(mod), bin} end)
      |> List.flatten()

    %{codegen | modules_generated: modules_generated ++ codegen.modules_generated}
  end
end
