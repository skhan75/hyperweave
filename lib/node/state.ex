defmodule Hyperweave.Node.State do
  @moduledoc """
  Represents the state for the NodeSupervisor, including node_id, neighbors,
  last heartbeat data, and metrics.
  """

  defstruct [
    :node_id,
    neighbors: %{},        # Map of neighbors and their states
    last_heartbeat: %{},   # Map of neighbor IDs to last heartbeat timestamps
    metrics: %{messages_sent: 0, messages_received: 0}
  ]
end
