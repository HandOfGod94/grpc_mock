defmodule GrpcMock.PbDynamicCompiler.CompileStatus do
  defstruct [:status, :error]
  @type status :: :failed | :finished
  @type t :: %__MODULE__{
          status: status(),
          error: any() | nil
        }
end
