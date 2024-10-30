defmodule Hyperweave.Node.NodeSupervisor do
  use GenServer
  require Logger

  alias Hyperweave.Node.State

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
    Logger.info("Initializing NodeSupervisor for node #{node_id}.")

    # Initialize with initial state
    initial_state = %State{
      node_id: node_id,
      neighbors: %{},
      last_heartbeat: %{},
      metrics: %{messages_sent: 0, messages_received: 0}
    }

    # Schedule a recurring heartbeat `:send_heartbeat` message every heartbeat interval
    :timer.send_interval(@heartbeat_interval, :check_neighbor_health)

    {:ok, initial_state}
  end

  # Periodically checks the health of neighbors based on their last heartbeat timestamp
  def handle_info(:check_neighbor_health, state) do
    Logger.debug("Running periodic health check for neighbors of node #{state.node_id}.")
    new_state = check_neighbor_health(state)
    {:noreply, new_state}
  end

   # Checks neighbors' health status, marking unresponsive ones as inactive if timeout is exceeded.
  defp check_neighbor_health(state) do
    current_time = System.monotonic_time(:millisecond)

    Enum.reduce(state.neighbors, state, fn {_direction, neighbor}, acc_state ->
      last_heartbeat = Map.get(acc_state.last_heartbeat, neighbor, current_time)

      if current_time - last_heartbeat > @heartbeat_timeout do
        Logger.warning("Neighbor #{neighbor} is unresponsive and will be marked inactive.")
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
    try do
    # Verify that `neighbors` is a map and the `neighbor` key exists.
    case Map.fetch(state.neighbors, neighbor) do
      {:ok, _} ->
        # Safely update the neighbor's status to `:inactive`
        updated_neighbors = Map.update!(state.neighbors, neighbor, fn _ -> :inactive end)

        # Log the action for debugging
        Logger.info("Marked neighbor #{neighbor} as inactive.")

        # Return updated state
        %{state | neighbors: updated_neighbors}

      :error ->
        # Log an error if the neighbor is not found in the map
        Logger.error("Failed to mark neighbor #{neighbor} as inactive: neighbor not found in state.")
        state  # Return state unchanged
    end
  rescue
    exception ->
      # Log any unexpected errors for debugging
      Logger.error("An error occurred while marking neighbor #{neighbor} as inactive: #{inspect(exception)}")
      state  # Return state unchanged
  end
    update_in(state.neighbors[neighbor], fn _ -> :inactive end)
  end

  # Notifies other components (MeshSupervisor and Routing) about an inactive neighbor
  defp notify_mesh_and_routing(state, neighbor) do
    # TODO-Uncomment these lines once MeshSupervisor and Routing are implemented:
    # Hyperweave.MeshSupervisor.handle_neighbor_failure(neighbor, state.node_id)
    # Hyperweave.Routing.handle_neighbor_failure(neighbor, state.node_id)
    state
  end


end
