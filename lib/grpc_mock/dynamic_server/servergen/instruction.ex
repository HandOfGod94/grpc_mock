defmodule GrpcMock.DynamicServer.Servergen.Instruction do
  alias GrpcMock.DynamicServer.Servergen
  alias GrpcMock.DynamicServer.Server
  alias GrpcMock.DynamicServer.ImplmentationGenerator

  @dialyzer {:no_match, decode_instruction: 2}

  @type instruction ::
          {:build_server_struct, params: map()}
          | {:generate_implmentation, template: String.t()}
          | {:launch}

  @type mfa_tuple :: {module(), function_name :: atom(), args :: [any()]}

  @spec decode_instruction(Servergen.t(), instruction()) :: {Servergen.t(), mfa_tuple()}
  def decode_instruction(servergen, {:build_server_struct, params: params}) do
    servergen =
      case Server.new(params) do
        {:ok, server} -> Servergen.set_server(servergen, server)
        {:error, changeset} -> Servergen.add_error(servergen, changeset)
      end

    {servergen, noop_mfa(servergen)}
  end

  def decode_instruction(servergen, {:generate_implmentation, template: template}) do
    servergen =
      with %{server: server} when server != nil <- servergen,
           {:ok, modules} <- ImplmentationGenerator.generate(server, template),
           [_service, endpoint] <- modules,
           {endpoint_mod, _, _} <- endpoint do
        Servergen.set_endpoint(servergen, endpoint_mod)
      else
        error -> Servergen.add_error(servergen, {:generate_implmentation, error})
      end

    {servergen, noop_mfa(servergen)}
  end

  def decode_instruction(servergen, {:launch}) do
    {servergen, {Server, :start, [servergen.server, servergen.endpoint]}}
  end

  defp noop_mfa(value), do: {Function, :identity, [value]}
end
