defmodule GrpcMock.DynamicCompiler.EExLoader do
  require Logger
  import GrpcMock.DynamicCompiler.Codegen
  alias GrpcMock.DynamicCompiler.Codegen.ModulesRepo

  @type t :: %__MODULE__{template: String.t(), bindings: keyword(atom())}
  defstruct [:template, :bindings, modules_generated: []]

  @topic Application.compile_env(:grpc_mock, :compile_status_updates_topic)

  @spec load_modules(String.t(), keyword(atom())) :: {:ok, t()} | {:error, any()}
  def load_modules(template, bindings) do
    %__MODULE__{template: template, bindings: bindings}
    |> cast()
    |> generate_modules_with(&eex_compile/1)
    |> save_with(ModulesRepo)
    |> broadcast_status(@topic, %{status: :done})
    |> apply_instruction()
  end

  defp eex_compile(codegen) do
    template = get_field(codegen, :template)
    bindings = get_field(codegen, :bindings)

    try do
      modules =
        template
        |> EEx.compile_file()
        |> Code.eval_quoted(bindings)
        |> then(fn {content, _bindings} -> content end)
        |> Code.compile_string()

      {:ok, modules}
    rescue
      error -> {:error, error}
    end
  end
end
