defmodule GrpcMock.MnesiaSyncTask do
  use Task, restart: :transient

  @moduledoc """
  In a cluster setup, esp. with orchestration engine like Kubernetes
  we will not have predictable Node names, and hence the Mnesia needs
  to be synced when application starts up.

  This task will try to sync with the first reachable node while
  application is starting up.
  """

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_args) do
    Node.list()
    |> Enum.at(0)
    |> Mnesiac.join_cluster()
  end
end
