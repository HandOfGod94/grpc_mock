defmodule GrpcMock.Codegen.EExLoader do
  require Logger

  import GrpcMock.Codegen.Modules.Store

  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo
  alias GrpcMock.Extension.Code, as: ExtCode

  def load_modules(template, bindings) do
    template
    |> EEx.compile_file()
    |> Code.eval_quoted(bindings)
    |> then(fn {content, _bindings} -> content end)
    |> Code.compile_string()
    |> tap(&remote_load/1)
    |> tap(&save_to_db/1)
  end

  defp remote_load(modules) do
    Enum.each(modules, fn {module_name, module_code} ->
      ExtCode.remote_load(module_name, module_code)
    end)
  end

  defp save_to_db(modules) do
    modules
    |> Enum.map(fn {module_name, module_code} ->
      dyn_module(
        id: module_name,
        name: module_name,
        filename: ExtCode.dynamic_module_filename(module_name),
        code_binary: module_code
      )
    end)
    |> ModuleRepo.save_all()
  end
end
