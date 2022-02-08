defmodule GrpcMock.DynamicCompiler.Codegen do
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
       {:compile, generator_fn: fn -> protoc_decdoer() end}
       {:publish, {:code, nodes: [:"foo@machine", :"bar@machine"]}, data_fn: &derive/1}
       {:publish, {:pubsub, topic: "sometopic", message: %{status: "success"}}}
       {:save {:modules_generated, repo: ModuleRepo, records_fn: &dervive/1}}
     ],
     status: :todo
   }
  """

  require Logger

  import GrpcMock.DynamicCompiler.Codegen.ModulesStore
  import GrpcMock.DynamicCompiler.Codegen.Instruction

  alias GrpcMock.DynamicCompiler.Codegen.Instruction

  @compile_status_topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)

  defstruct parent_mod: nil,
            fields: %{},
            modules_generated: [],
            status: :todo,
            instructions: [],
            failure_topic: @compile_status_topic,
            valid?: true,
            errors: []

  @type args :: any()
  @type dynamic_module :: {module(), binary(), filename :: charlist()}
  @type status :: :todo | :in_progress | :done

  @type t :: %__MODULE__{
          parent_mod: module() | nil,
          fields: [atom()] | %{},
          modules_generated: [dynamic_module()],
          instructions: [Instruction.instruction()],
          status: status(),
          failure_topic: String.t(),
          valid?: boolean(),
          errors: [any()]
        }

  @spec cast(struct()) :: t()
  def cast(struct) do
    parent_mod = struct.__struct__

    %__MODULE__{
      parent_mod: parent_mod,
      fields: Map.from_struct(struct)
    }
  end

  @spec get_field(t(), atom()) :: any()
  def get_field(%__MODULE__{} = codegen, field), do: codegen.fields[field]

  @spec generate_modules_with(t(), Instruction.generator_fn()) :: t()
  def generate_modules_with(%__MODULE__{} = codegen, generator_fn) when is_function(generator_fn, 1) do
    compile = {:compile, generator_fn: generator_fn}
    codegen |> put_instruction(compile)
  end

  @spec save_with(t(), module()) :: t()
  def save_with(%__MODULE__{} = codegen, repo) do
    records_fn = fn codegen ->
      codegen.modules_generated
      |> Enum.map(fn {mod, filename, bin} ->
        dyn_module(id: mod, name: mod, filename: filename, code_binary: bin)
      end)
    end

    instruction = {:save, {:modules_generated, repo: repo, records_fn: records_fn}}

    codegen |> put_instruction(instruction)
  end

  @spec broadcast_status(t(), String.t(), any()) :: t()
  def broadcast_status(%__MODULE__{} = codegen, topic, message) do
    instruction = {:publish, {:pubsub, topic: topic, message: message}}
    codegen |> put_instruction(instruction)
  end

  @spec add_error(t(), any()) :: t()
  def add_error(%__MODULE__{} = codegen, error) do
    %{codegen | valid?: false, errors: [error | codegen.errors]}
  end

  defp put_instruction(%__MODULE__{} = codegen, instruction) do
    %{codegen | instructions: [instruction | codegen.instructions]}
  end

  defp get_instructions(%__MODULE__{} = codegen), do: Enum.reverse(codegen.instructions)

  ## instructions applier

  @spec apply_instruction(t()) :: {:ok, struct()} | {:error, any()}
  def apply_instruction(%__MODULE__{} = codegen) do
    codegen =
      codegen
      |> get_instructions()
      |> Enum.reduce(codegen, &do_apply(&2, &1))
      |> Map.put(:instructions, [])
      |> Map.put(:status, :done)

    if codegen.valid? do
      fields = %{codegen.fields | modules_generated: codegen.modules_generated}
      codegen = %{codegen | fields: fields}
      {:ok, struct!(codegen.parent_mod, codegen.fields)}
    else
      {:error, codegen.errors}
    end
  end

  defp do_apply(%__MODULE__{valid?: true} = state, instruction) do
    Logger.info("applying codegen instruction: #{inspect(instruction)}")

    {state, {mod, fun, args}} = decode_instruction(state, instruction)
    if state.valid?, do: apply(mod, fun, args), else: publish_failure(state)

    Logger.info("applied codegen instruction")
    state
  end

  defp do_apply(state, instruction) do
    Logger.warning("skipping codegen #{inspect(instruction)} because of error in previous step")
    state
  end

  defp publish_failure(%__MODULE__{} = codegen) do
    Phoenix.PubSub.broadcast!(GrpcMock.PubSub, codegen.failure_topic, %{status: :failed, reason: codegen.errors})
  end
end
