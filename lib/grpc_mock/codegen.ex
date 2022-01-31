defmodule GrpcMock.Codegen do
  @moduledoc """
   Load multiple dynamically generated modules at runtime.
   It will hold all the required information for genrating dynamic code from `eex` or `proto`.any()
  """

  defmacro __using__(_opts) do
    quote do
      import GrpcMock.Codegen.Instruction
    end
  end
end
