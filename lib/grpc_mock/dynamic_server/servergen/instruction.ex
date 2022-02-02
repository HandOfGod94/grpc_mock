defmodule GrpcMock.DynamicServer.Servergen.Instruction do
  alias GrpcMock.DynamicServer.Servergen
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicServer.ImplmentationGenerator

  def decode_instruction(servergen, {:build_server_struct, params: params}) do
    servergen =
      case Server.new(params) do
        {:ok, server} -> Servergen.set_server(servergen, server)
        {:error, changeset} -> Servergen.add_error(servergen, changeset)
      end

    {servergen, {Function, :identity, [servergen]}}
  end

  def decode_instruction(servergen, {:generate_implmentation}) do
    servergen =
      with {:ok, modules} <- ImplmentationGenerator.generate(servergen.server),
           [_service, endpoint] <- modules,
           {endpoint_mod, _, _} <- endpoint do
        Servergen.set_endpoint(servergen, endpoint_mod)
      else
        error -> Servergen.add_error(servergen, {:generate_implmentation, error})
      end

    {servergen, {Function, :identity, [servergen]}}
  end

  def decode_instruction(servergen, {:start, nodes: nodes}) do
    {servergen, {Server, :start, [servergen.server, servergen.endpoint, nodes]}}
  end

  def decode_instruction(servergen, {:save, repo: repo, records_fn: records_fn}) do
    records = records_fn.(servergen)
    {servergen, {repo, :save, [records]}}
  end
end
