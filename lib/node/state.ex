defmodule Hyperweave.Node.State do
  @moduledoc """
  Defines the state structure for the NodeSupervisor, including node ID, neighbors,
  last heartbeat records, and metrics.
  """

  alias Hyperweave.Node.Neighbors

  @type t :: %__MODULE__{
          node_id: any(),
          neighbors: Neighbors.t(),       # Stores neighbors by direction
          last_heartbeat: map(),          # Map of neighbor IDs to last heartbeat timestamps
          metrics: map()                  # Additional performance metrics
        }

  defstruct [
    :node_id,
    neighbors: Neighbors.new(),          # Use Neighbors struct for organization
    last_heartbeat: %{},
    metrics: %{messages_sent: 0, messages_received: 0}
  ]
end
