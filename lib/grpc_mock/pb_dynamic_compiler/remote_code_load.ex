defmodule GrpcMock.PbDynamicCompiler.RemoteCodeLoad do
  @moduledoc """
  When we compile and load the `.pb.ex`, the loaded code remains with the node which did compilation.
  In cluster setup, we need all the nodes to have the same compiled code, so that server mocks can work correctly.

  This task will publish code to all the nodes.
  """

  @type rpc_call_result :: term() | {:badrpc, term()}

  @spec publish(atom(), charlist(), binary()) :: list(rpc_call_result())
  def publish(module_name, filename, module_code) when is_list(filename) do
    for node <- Node.list() do
      :rpc.call(node, :code, :load_binary, [module_name, filename, module_code])
    end
  end
end
