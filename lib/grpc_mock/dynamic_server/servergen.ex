defmodule GrpcMock.DynamicServer.Servergen do
  @moduledoc """
  Provides data driven api for creating dynamic servers

  A typical examples of instructions that can be used while creating servers can be:

  ```elixir
  instructions =
    [
      {:build_server_struct, params: %{service: "FooService", method: "do_foo"}},
      {:generate_implmentation},
      {:start, nodes: [:"foo@other.com", :"bar@other.com"]},
      {:save, repo: ServerRepo, records_fn: &derive_server_details/1}
    ]
  ```
  """

  require Logger
  import GrpcMock.DynamicServer.Servergen.Instruction
  alias GrpcMock.DynamicServer.Servergen.Instruction
  alias GrpcMock.DynamicServer.Server

  defstruct server: %Server{}, endpoint: nil, valid?: true, errors: [], instructions: []

  @type t :: %__MODULE__{
          server: Server.t(),
          endpoint: module(),
          valid?: boolean(),
          errors: [any()],
          instructions: [Instruction.instruction()]
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec set_server(t(), Server.t()) :: t()
  def set_server(servergen, server) do
    %{servergen | server: server}
  end

  @spec set_endpoint(t(), module()) :: t()
  def set_endpoint(servergen, endpoint) do
    %{servergen | endpoint: endpoint}
  end

  @spec add_error(t(), any()) :: t()
  def add_error(servergen, errors) do
    %{servergen | valid?: false, errors: [errors | servergen.errors]}
  end

  @spec changeset_error(t()) :: Ecto.Changeset.t() | nil
  def changeset_error(servergen) do
    Enum.find(servergen.errors, &match?(%Ecto.Changeset{}, &1))
  end

  @spec build_server_struct(t(), map()) :: t()
  def build_server_struct(servergen, params) do
    servergen |> put_instruction({:build_server_struct, params: params})
  end

  @spec generate_implmentation(t(), template: filename) :: t() when filename: String.t()
  def generate_implmentation(servergen, template: template) do
    servergen |> put_instruction({:generate_implmentation, template: template})
  end

  @spec launch(t()) :: t()
  def launch(servergen) do
    servergen |> put_instruction({:launch})
  end

  @spec put_instruction(t(), Instruction.instruction()) :: t()
  defp put_instruction(servergen, instruction) do
    %{servergen | instructions: [instruction | servergen.instructions]}
  end

  defp take_instructions(servergen), do: Enum.reverse(servergen.instructions)

  @spec apply_instruction(t()) :: t()
  def apply_instruction(%__MODULE__{} = servergen) do
    servergen
    |> take_instructions()
    |> Enum.reduce(servergen, &do_apply(&2, &1))
    |> Map.put(:instructions, [])
  end

  defp do_apply(%__MODULE__{valid?: true} = state, instruction) do
    Logger.info("applying servergen instruction: #{inspect(instruction)}")

    {state, {mod, fun, args}} = decode_instruction(state, instruction)
    if state.valid?, do: apply(mod, fun, args)

    Logger.info("applied servergen instruction")
    state
  end

  defp do_apply(state, instruction) do
    Logger.warning("skipping servergen #{inspect(instruction)} because of error in previous step")
    state
  end
end
