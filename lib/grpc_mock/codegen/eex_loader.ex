defmodule GrpcMock.Codegen.EExLoader do
  require Logger

  import GrpcMock.Codegen.Modules.Store

  alias GrpcMock.Codegen.Modules.Repo, as: ModuleRepo
  alias GrpcMock.Extension.Code, as: ExtCode

  @otp_app :grpc_mock

  def load_modules(template, bindings) do
    :code.priv_dir(@otp_app)
    |> Path.join(template)
    |> EEx.compile_file()
    |> Code.eval_quoted(bindings)
    |> then(fn {content, _bindings} -> content end)
    |> tap(&publish/1)
    |> tap(&save_to_db/1)
  end

  defp publish(modules) do
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
