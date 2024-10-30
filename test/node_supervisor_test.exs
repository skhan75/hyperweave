defmodule Hyperweave.Node.NodeSupervisorTest do
  use ExUnit.Case, async: false
  require Logger
  alias Hyperweave.Node.NodeSupervisor
  alias Hyperweave.Node

  @moduletag :node_supervisor_tests
  import ExUnit.CaptureLog

  setup do
    # Capture any remaining logs to clear before starting each test
    _ = capture_log(fn -> :ok end)

    # Start the NodeSupervisor and ensure it is alive
    {:ok, pid} = NodeSupervisor.start_link(:test_node)
    assert Process.alive?(pid)

    # Set up `on_exit` callbacks to clean up after each test
    on_exit(fn ->
      Process.exit(pid, :normal)
      _ = capture_log(fn -> :ok end) # Capture any lingering logs again after the test
    end)

    # Return the initial state map with the process id
    %{supervisor_pid: pid}
  end



  @tag :initialization
  test "initializes NodeSupervisor with expected state values", %{supervisor_pid: pid} do
    # Check initial state of GenServer
    state = :sys.get_state(pid)
    assert state.node_id == :test_node
    assert %Hyperweave.Node.Neighbors{} = state.neighbors
    assert map_size(state.last_heartbeat) == 0
    assert state.metrics == %{messages_sent: 0, messages_received: 0}
    IO.inspect(state, label: "Initial State")
  end

  @tag :initial_state
  test "initializes NodeSupervisor with expected state values and empty neighbors", %{supervisor_pid: pid} do
    send(pid, :check_neighbor_health)
    Process.sleep(150)  # Wait for health check processing
    state = :sys.get_state(pid)

    # Check neighbors
    assert state.neighbors.x_pos == nil
    assert state.neighbors.x_neg == nil
    assert state.neighbors.y_pos == nil
    assert state.neighbors.y_neg == nil
    assert state.neighbors.z_pos == nil
    assert state.neighbors.z_neg == nil
    assert state.node_id == :test_node
    assert map_size(state.last_heartbeat) == 0
    assert state.metrics == %{messages_sent: 0, messages_received: 0}
  end

  @tag :health_check
  test "periodic health check marks inactive neighbors", %{supervisor_pid: pid} do
    # Set old timestamps for heartbeat, add neighbors, and run check
    old_time = System.system_time(:millisecond) - 20_000
    :sys.replace_state(pid, fn state ->
      neighbors = %{
        x_pos: %Node{id: :neighbor_1, state: :active},
        y_pos: %Node{id: :neighbor_2, state: :active}
      }
      last_heartbeat = %{neighbor_1: old_time, neighbor_2: old_time}
      %{state | neighbors: neighbors, last_heartbeat: last_heartbeat}
    end)

    send(pid, :check_neighbor_health)
    Process.sleep(150)  # Wait for health check processing
    state = :sys.get_state(pid)

    # Verify both neighbors are inactive
    assert state.neighbors.x_pos.state == :inactive
    assert state.neighbors.y_pos.state == :inactive
  end

  @tag :inactive_neighbor_with_id_check
  test "marks neighbor inactive only if the neighbor_id matches the expected ID", %{supervisor_pid: pid} do
    :sys.replace_state(pid, fn state ->
      neighbors = %{x_pos: %Node{id: :neighbor_1, state: :active}}
      %{state | neighbors: neighbors}
    end)

    # Clear logs and capture correct log for marking inactive
    _ = capture_log(fn -> :ok end)
    Process.sleep(50)

    log = capture_log([timeout: 1000], fn ->
      GenServer.call(pid, {:mark_inactive, :x_pos, :neighbor_1})
    end)
    assert log =~ "Marked neighbor in direction :x_pos as inactive in the supervisor state."

    # Verify neighbor is inactive
    state = :sys.get_state(pid)
    assert state.neighbors.x_pos.state == :inactive

    # Clear logs and capture mismatch log for incorrect ID
    _ = capture_log(fn -> :ok end)
    Process.sleep(50)

    log_mismatch = capture_log([timeout: 1000], fn ->
      GenServer.call(pid, {:mark_inactive, :x_pos, :incorrect_id})
    end)
    assert log_mismatch =~ "Neighbor mismatch in direction :x_pos: expected :incorrect_id, found :neighbor_1."
    state = :sys.get_state(pid)
    assert state.neighbors.x_pos.state == :inactive
  end

  @tag :update_neighbor_status
  test "handle_cast correctly updates neighbor status", %{supervisor_pid: pid} do
    GenServer.cast(pid, {:update_neighbor, :x_pos, %Node{id: :neighbor_1, state: :active}})
    GenServer.cast(pid, {:update_neighbor, :y_pos, %Node{id: :neighbor_2, state: :active}})
    state = :sys.get_state(pid)

    # Verify neighbors are updated correctly
    assert state.neighbors.x_pos.state == :active
    assert state.neighbors.y_pos.state == :active
  end

  @tag :error_handling
  test "handles errors gracefully in mark_neighbor_inactive", %{supervisor_pid: pid} do
    _ = capture_log(fn -> :ok end)
    Process.sleep(50)

    log = capture_log([timeout: 1000], fn ->
      GenServer.call(pid, {:mark_inactive, :nonexistent_neighbor, :placeholder_id})
    end)
    assert log =~ "No neighbor found in direction :nonexistent_neighbor in supervisor state to mark as inactive."
  end

  @tag :already_inactive_neighbor
  test "does not change state if neighbor is already inactive", %{supervisor_pid: pid} do
    :sys.replace_state(pid, fn state ->
      neighbors = %{x_pos: %Node{id: :neighbor_1, state: :inactive}}
      %{state | neighbors: neighbors}
    end)

    _ = capture_log(fn -> :ok end)
    Process.sleep(50)

    log = capture_log([timeout: 1000], fn ->
      GenServer.call(pid, {:mark_inactive, :x_pos, :neighbor_1})
    end)
    assert log =~ "Neighbor in direction :x_pos is already marked as inactive."

    # Confirm state remains inactive
    state = :sys.get_state(pid)
    assert state.neighbors.x_pos.state == :inactive
  end
end
