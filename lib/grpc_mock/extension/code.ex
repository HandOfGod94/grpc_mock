defmodule GrpcMock.Extension.Code do
  require Logger

  @type rpc_call_result :: term() | {:badrpc, term()}

  @doc """
  Loads dynamically generated module to all the remote node
  """

  def remote_load(modules, nodes) when is_list(modules) and is_list(nodes) do
    for {mod_name, filename, mod_code} <- modules do
      remote_load(mod_name, filename, mod_code, nodes)
    end
  end

  @spec remote_load(module(), charlist(), binary(), [node()]) :: list(rpc_call_result())
  def remote_load(module_name, filename, module_code, nodes) when is_list(filename) and is_list(nodes) do
    for node <- nodes, into: [] do
      remote_load(module_name, filename, module_code, node)
    end
  end

  @spec remote_load(atom(), charlist(), binary(), node()) :: list(rpc_call_result())
  def remote_load(module_name, filename, module_code, node) when is_list(filename) do
    Logger.debug("Loading binary for #{module_name} on #{node}")

    case :rpc.call(node, :code, :load_binary, [module_name, filename, module_code]) do
      {:badrpc, reason} -> raise RuntimeError, message: "Unable to load binary on node. reason: #{inspect(reason)}"
      ok -> ok
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
