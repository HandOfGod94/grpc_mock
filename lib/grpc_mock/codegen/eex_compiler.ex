defmodule GrpcMock.Codegen.EExCompiler do
  def compile(template, bindings) do
    template
    |> EEx.compile_file()
    |> Code.eval_quoted(bindings)
    |> then(fn {content, _bindings} -> content end)
  end
end
