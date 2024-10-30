defmodule Hyperweave.NodeSupervisor do
  use GenServer
  alias Hyperweave.Node

  # Set up heartbeat intervals and timeouts, falling back to defaults if not set in config.
  @heartbeat_interval Application.compile_env(:hyperweave, :heartbeat_interval) || 5_000 # 5 seconds
  @heartbeat_timeout Application.compile_env(:hyperweave, :heartbeat_timeout) || 15_000 # 15 seconds

  # Start the NodeSupervisor for a given Node ID
  # This function starts the supervisor for a given node_id by initiating a GenServer. It manages the lifecycle of the node's monitoring functions
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(node_id) do
    GenServer.start_link(__MODULE__, node_id, name: __MODULE__)
  end

  # Initialize the NodeSupervisor with the node's state and starts the heartbeat monitoring
  def init(node_id) do
    # Schedule a recurring heartbeat `:send_heartbeat` message every heartbeat interval
    :timer.send_interval(@heartbeat_interval, :check_neighbor_health)
    # Set up the node's initial state with an empty map for last_heartbeat timestamps
    {:ok, %Node{id: node_id, last_heartbeat: %{}}, {:continue, :initialize_heartbeat}}
  end

  # Periodically checks the health of neighbors based on their last heartbeat timestamp
  def handle_info(:check_neighbor_health, state) do
    state = check_neighbor_health(state)
    {:noreply, state}
  end

  # Checks the health of neighbors and marks inactive ones
  defp check_neighbor_health(state) do
    current_time = System.monotonic_time(:millisecond)

    Enum.reduce(state.neighbors, state, fn {_direction, neighbor}, acc_state ->
      last_heartbeat = Map.get(acc_state.last_heartbeat, neighbor, current_time)

      if current_time - last_heartbeat > @heartbeat_timeout do
        acc_state
        |> mark_neighbor_inactive(neighbor)
        |> notify_mesh_and_routing(neighbor)
      else
        acc_state
      end
    end)
  end

  # Marks a neighbor as inactive in the node's state
  defp mark_neighbor_inactive(state, neighbor) do
    # Update the neighbors map, marking this neighbor as inactive
    update_in(state.neighbors[neighbor], fn _ -> :inactive end)
  end

  # Notifies other components (MeshSupervisor and Routing) about an inactive neighbor
  defp notify_mesh_and_routing(state, neighbor) do
    # Hyperweave.MeshSupervisor.handle_neighbor_failure(neighbor, state.node_id)
    # Hyperweave.Routing.handle_neighbor_failure(neighbor, state.node_id)
    state
  end


end
