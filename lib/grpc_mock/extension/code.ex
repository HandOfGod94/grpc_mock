defmodule GrpcMock.Extension.Code do
  @type rpc_call_result :: term() | {:badrpc, term()}

  @doc """
  Loads dynamically generated module to all the remote node
  """
  @spec remote_load(atom(), binary()) :: list(rpc_call_result())
  def remote_load(module_name, module_code) do
    remote_load(module_name, dynamic_module_filename(module_name), module_code)
  end

  @spec remote_load(atom(), charlist(), binary()) :: list(rpc_call_result())
  def remote_load(module_name, filename, module_code) when is_list(filename) do
    for node <- Node.list() do
      :rpc.call(node, :code, :load_binary, [module_name, filename, module_code])
    end
  end

  def dynamic_module_filename(module) do
    module
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
    |> to_charlist()
  end
end
