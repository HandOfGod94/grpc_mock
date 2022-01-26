defmodule GrpcMock.MnesiaSyncTask do
  use Task, restart: :transient
  alias GrpcMock.Codegen.DbLoader

  ## TODO: this taks is hack. Better implementation should wait for reachable nodes
  ## to be discoverable via `libcluster` and then Mnesia should join cluster.

  @moduledoc """
  In a cluster setup, esp. with orchestration engine like Kubernetes
  we will not have predictable Node names, and hence the Mnesia needs
  to be synced when application starts up.

  This task will try to sync with the first reachable node while
  application is starting up.
  """

  @spec start_link(term()) :: {:ok, pid()}
  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  @spec run(any()) :: :ok | {:error, term()} | nil
  def run(_args) do
    join_cluster()
    DbLoader.load_modules()
  end

  defp join_cluster do
    if Node.list() != [] do
      Node.list() |> Mnesiac.init_mnesia()
    end
  end
end
