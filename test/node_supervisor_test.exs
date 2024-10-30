defmodule Hyperweave.Node.NodeSupervisorTest do
  use ExUnit.Case, async: true
  require Logger
  Logger.configure(level: :debug)

  alias Hyperweave.Node.NodeSupervisor
  alias Hyperweave.Node

  @moduletag :node_supervisor_tests

  import ExUnit.CaptureLog

  setup do
    {:ok, pid} = NodeSupervisor.start_link(:test_node)
    assert Process.alive?(pid)  # Confirm that the process is running
    %{supervisor_pid: pid}
  end

  @tag :initialization
  test "initializes NodeSupervisor with expected state values", %{supervisor_pid: pid} do
    # Fetch the initial state of the GenServer
    state = :sys.get_state(pid)

    # Assertions for initial state values
    assert state.node_id == :test_node

    # Since neighbors might have been initialized differently, let's ensure it's an empty struct
    assert %Hyperweave.Node.Neighbors{} = state.neighbors
    assert map_size(state.last_heartbeat) == 0
    assert state.metrics == %{messages_sent: 0, messages_received: 0}

    # Debugging output if needed
    IO.inspect(state, label: "Initial State")
  end

  @tag :initial_state
  test "initializes NodeSupervisor with expected state values and empty neighbors", %{supervisor_pid: pid} do
    # Trigger the health check
    send(pid, :check_neighbor_health)
    Process.sleep(100)  # Allow time for the message to be processed

    # Fetch the current state to verify changes
    state = :sys.get_state(pid)

    # Check that each directional neighbor in `neighbors` is `nil` (indicating no active neighbors)
    assert state.neighbors.x_pos == nil
    assert state.neighbors.x_neg == nil
    assert state.neighbors.y_pos == nil
    assert state.neighbors.y_neg == nil
    assert state.neighbors.z_pos == nil
    assert state.neighbors.z_neg == nil

    # Additional verification for other attributes if necessary
    assert state.node_id == :test_node
    assert map_size(state.last_heartbeat) == 0
    assert state.metrics == %{messages_sent: 0, messages_received: 0}
  end

  @tag :health_check
  test "periodic health check marks inactive neighbors", %{supervisor_pid: pid} do
    # Set an old timestamp for heartbeat that exceeds the heartbeat timeout
    old_time = System.system_time(:millisecond) - 20_000  # 20 seconds ago

    # Add two neighbors directly to the supervisor state with an outdated last heartbeat
    :sys.replace_state(pid, fn state ->
      neighbors = %{
        x_pos: %Node{id: :neighbor_1, state: :active},
        y_pos: %Node{id: :neighbor_2, state: :active}
      }

      last_heartbeat = %{
        :neighbor_1 => old_time,
        :neighbor_2 => old_time
      }

      %{state | neighbors: neighbors, last_heartbeat: last_heartbeat}
    end)

    # Trigger the health check and wait for it to be processed
    send(pid, :check_neighbor_health)
    Process.sleep(100)  # Ensure the health check completes

    # Verify that neighbors are marked inactive in the supervisor state after the health check
    state = :sys.get_state(pid)

    assert state.neighbors.x_pos.state == :inactive
    assert state.neighbors.y_pos.state == :inactive
  end

  @tag :inactive_neighbor_with_id_check
  test "marks neighbor inactive only if the neighbor_id matches the expected ID", %{supervisor_pid: pid} do
    # Set an initial state with an active neighbor
    :sys.replace_state(pid, fn state ->
      neighbors = %{
        x_pos: %Node{id: :neighbor_1, state: :active}
      }
      %{state | neighbors: neighbors}
    end)

    # Capture logs and attempt to mark the neighbor as inactive using the correct neighbor_id
    log =
      capture_log(fn ->
        GenServer.call(pid, {:mark_inactive, :x_pos, :neighbor_1})  # Correct ID
      end)

    # Check log to verify the neighbor was marked inactive
    assert log =~ "Marked neighbor in direction :x_pos as inactive in the supervisor state."

    # Fetch the updated state
    state = :sys.get_state(pid)

    # Assert the neighbor was marked as inactive
    assert state.neighbors.x_pos.state == :inactive

    # Now, test with an incorrect neighbor_id
    log_mismatch =
      capture_log(fn ->
        GenServer.call(pid, {:mark_inactive, :x_pos, :incorrect_id})  # Incorrect ID
      end)

    # Verify that a mismatch log is captured
    assert log_mismatch =~ "Neighbor mismatch in direction :x_pos: expected :incorrect_id, found :neighbor_1."

    # Verify the neighbor state remains unchanged as inactive
    state = :sys.get_state(pid)
    assert state.neighbors.x_pos.state == :inactive
  end


  @tag :update_neighbor_status
  test "handle_cast correctly updates neighbor status", %{supervisor_pid: pid} do
    # Update the state to add neighbors in specific directions
    GenServer.cast(pid, {:update_neighbor, :x_pos, %Node{id: :neighbor_1, state: :active}})
    GenServer.cast(pid, {:update_neighbor, :y_pos, %Node{id: :neighbor_2, state: :active}})

    # Retrieve and verify the updated state
    state = :sys.get_state(pid)

    # Check that the neighbors have been updated correctly
    assert state.neighbors.x_pos.state == :active
    assert state.neighbors.y_pos.state == :active
  end

  @tag :error_handling
  test "handles errors gracefully in mark_neighbor_inactive", %{supervisor_pid: pid} do
    import ExUnit.CaptureLog

    log =
      capture_log(fn ->
        # Attempt to mark a non-existent neighbor as inactive with a placeholder ID
        GenServer.call(pid, {:mark_inactive, :nonexistent_neighbor, :placeholder_id})
      end)

    # Verify that the correct error message was logged
    assert log =~ "No neighbor found in direction :nonexistent_neighbor in supervisor state to mark as inactive."
  end

  @tag :already_inactive_neighbor
  test "does not change state if neighbor is already inactive", %{supervisor_pid: pid} do
    # Replace the state to initialize a neighbor as inactive
    :sys.replace_state(pid, fn state ->
      neighbors = %{
        x_pos: %Node{id: :neighbor_1, state: :inactive}
      }
      %{state | neighbors: neighbors}
    end)
    # Capture logs and attempt to mark the already inactive neighbor
    log =
      capture_log(fn ->
        GenServer.call(pid, {:mark_inactive, :x_pos, :neighbor_1})
      end)

    # Verify the log message indicates the neighbor was already inactive
    assert log =~ "Neighbor in direction :x_pos is already marked as inactive."
    # Retrieve and verify the updated state
    state = :sys.get_state(pid)
    # Check that the neighbors are still marked inactive
    assert state.neighbors.x_pos.state == :inactive
  end
end
