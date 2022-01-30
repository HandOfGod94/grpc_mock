defmodule GrpcMock.Extension.Code do
  @type rpc_call_result :: term() | {:badrpc, term()}

  @doc """
  Loads dynamically generated module to all the remote node
  """
  @spec remote_load(module(), binary(), [node()]) :: list(rpc_call_result())
  def remote_load(module_name, module_code, nodes \\ Node.list()) when is_list(nodes) do
    remote_load(module_name, dynamic_module_filename(module_name), module_code, nodes)
  end

  @spec remote_load(module(), charlist(), binary(), [node()]) :: list(rpc_call_result())
  def remote_load(module_name, filename, module_code, nodes) when is_list(filename) and is_list(nodes) do
    for node <- nodes, into: [] do
      remote_load(module_name, filename, module_code, node)
    end
  end

  @spec remote_load(atom(), charlist(), binary(), node()) :: list(rpc_call_result())
  def remote_load(module_name, filename, module_code, node) when is_list(filename) do
    :rpc.call(node, :code, :load_binary, [module_name, filename, module_code])
  end

  def dynamic_module_filename(module) do
    module
    |> Atom.to_string()
    |> String.replace(".", "_")
    |> String.downcase()
    |> to_charlist()
  end
end
