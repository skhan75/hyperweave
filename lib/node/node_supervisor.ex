defmodule Hyperweave.Node.NodeSupervisor do
  use GenServer
  require Logger
  Logger.configure(level: :debug)

  alias Hyperweave.Node
  alias Hyperweave.Node.Neighbors

  # Set up heartbeat intervals and timeouts
  @heartbeat_interval Application.compile_env(:hyperweave, :heartbeat_interval) || 5_000 # 5 seconds
  @heartbeat_timeout Application.compile_env(:hyperweave, :heartbeat_timeout) || 15_000 # 15 seconds

  # Start the NodeSupervisor for a given Node ID
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(node_id) do
    GenServer.start_link(__MODULE__, node_id, name: __MODULE__)
  end

  # Initialize the NodeSupervisor with the node's metadata and heartbeat tracking
  def init(node_id) do
    Logger.info("Initializing NodeSupervisor for node #{node_id}.")

    # Initial supervisor state: tracks neighbors, heartbeat, and metrics
    initial_state = %{
      node_id: node_id,
      neighbors: Neighbors.new(),
      last_heartbeat: %{},
      metrics: %{messages_sent: 0, messages_received: 0}
    }

    # Print the initial state to the console
    IO.inspect(initial_state, label: "Initial State")

    # Schedule periodic heartbeat checks
    :timer.send_interval(@heartbeat_interval, :check_neighbor_health)

    {:ok, initial_state}
  end

  # Periodically checks the health of neighbors based on last heartbeat timestamp
  def handle_info(:check_neighbor_health, state) do
    Logger.debug("Running periodic health check for neighbors of node #{state.node_id}.")
    new_state = check_neighbor_health(state)
    {:noreply, new_state}
  end

  # Handle synchronous call to get state
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Handle synchronous call for marking a neighbor as inactive
  def handle_call({:mark_inactive, direction, neighbor_id}, _from, state) do
    updated_state = mark_neighbor_inactive(state, direction, neighbor_id)
    {:reply, :ok, updated_state}
  end

  # Handle asynchronous cast to update a neighbor’s status
  def handle_cast({:update_neighbor, neighbor_id, neighbor_state}, state) do
    updated_neighbors = Map.put(state.neighbors, neighbor_id, neighbor_state)
    new_state = %{state | neighbors: updated_neighbors}
    {:noreply, new_state}
  end

  # Check neighbor health status, mark as inactive in supervisor if needed
  defp check_neighbor_health(state) do
    current_time = System.system_time(:millisecond)
    Enum.reduce([:x_pos, :x_neg, :y_pos, :y_neg, :z_pos, :z_neg], state, fn direction, acc_state ->
      neighbor_coord = Neighbors.get_neighbor(acc_state.neighbors, direction)

      if neighbor_coord do
        last_heartbeat = Map.get(acc_state.last_heartbeat, neighbor_coord.id, nil)

        if last_heartbeat && current_time - last_heartbeat > @heartbeat_timeout do
          Logger.warning("Neighbor at #{inspect(neighbor_coord)} is unresponsive and will be marked inactive in the supervisor.")

          # Mark the neighbor as inactive in the supervisor's internal tracking only
          acc_state
          |> mark_neighbor_inactive(direction, neighbor_coord.id)
          |> notify_mesh_and_routing(neighbor_coord)
        else
          acc_state
        end
      else
        acc_state
      end
    end)
  end


  # Update the supervisor state when a neighbor is unresponsive (internal marking)
  defp mark_neighbor_inactive(state, direction, expected_neighbor_id) do
    try do
      neighbor = Map.get(state.neighbors, direction)

      case neighbor do
        # If the neighbor is not found, log a warning and return the unchanged state
        nil ->
          Logger.warning("No neighbor found in direction #{inspect(direction)} in supervisor state to mark as inactive.")
          state

        # If the neighbor is already inactive, log this information
        %Node{id: ^expected_neighbor_id, state: :inactive} ->
          Logger.warning("Neighbor in direction #{inspect(direction)} is already marked as inactive.")
          state

        # If the neighbor ID matches the expected ID and it's active, mark it inactive
        %Node{id: ^expected_neighbor_id} = neighbor_state ->
          updated_neighbor = %{neighbor_state | state: :inactive}
          updated_neighbors = Map.put(state.neighbors, direction, updated_neighbor)
          Logger.info("Marked neighbor in direction #{inspect(direction)} as inactive in the supervisor state.")
          %{state | neighbors: updated_neighbors}

        # If the neighbor ID does not match, log a mismatch warning
        %Node{id: neighbor_id} ->
          Logger.warning("Neighbor mismatch in direction #{inspect(direction)}: expected #{inspect(expected_neighbor_id)}, found #{inspect(neighbor_id)}.")
          state
      end
    rescue
      exception ->
        Logger.error("Error marking neighbor in direction #{inspect(direction)} as inactive in supervisor state: #{inspect(exception)}")
        state
    end
  end



  # Notifies the mesh or routing components about the neighbor status change
  defp notify_mesh_and_routing(state, _neighbor_coord) do
    # Once mesh and routing handle neighbor failure, update the actual `Node` if needed
    # Hyperweave.MeshSupervisor.handle_neighbor_failure(neighbor_coord, state.node_id)
    # Hyperweave.Routing.handle_neighbor_failure(neighbor_coord, state.node_id)
    state
  end
end
