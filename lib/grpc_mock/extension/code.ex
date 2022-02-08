defmodule GrpcMock.Extension.Code do
  @spec dynamic_module_filename(module()) :: charlist()
  def dynamic_module_filename(module) do
    module
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
    |> to_charlist()
  end
end
