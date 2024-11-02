defmodule Hyperweave.Mesh.NodeMapperTest do
  use ExUnit.Case
  alias Hyperweave.Mesh.NodeMapper
  alias Hyperweave.Coordinates

  @space_size 16

  describe "calculate_spatially_optimal_coordinate/1" do
    test "consistently produces the same h_index for the same node ID" do
      node_id = "node123"

      h_index1 = NodeMapper.calculate_spatially_optimal_coordinate(node_id)
      h_index2 = NodeMapper.calculate_spatially_optimal_coordinate(node_id)

      assert h_index1 == h_index2
    end

    # test "produces different h_indices for different node IDs" do
    #   node_id1 = "node123"
    #   node_id2 = "node456"

    #   h_index1 = NodeMapper.calculate_spatially_optimal_coordinate(node_id1)
    #   h_index2 = NodeMapper.calculate_spatially_optimal_coordinate(node_id2)

    #   refute h_index1 == h_index2
    # end

    # test "h_index falls within the valid range for a given @space_size" do
    #   node_id = "node789"
    #   max_hilbert_index = :math.pow(2, 3 * @space_size) |> trunc()

    #   h_index = NodeMapper.calculate_spatially_optimal_coordinate(node_id)

    #   assert h_index >= 0
    #   assert h_index < max_hilbert_index
    # end
  end

  # describe "hilbert_to_3d/2" do
  #   test "maps h_index to valid 3D coordinates within the mesh space" do
  #     # Assume this index is in range, just for demonstration
  #     h_index = 42
  #     coordinates = NodeMapper.hilbert_to_3d(h_index, @space_size)

  #     # Ensure the coordinates stay within bounds based on @space_size
  #     max_coord = Integer.pow(2, @space_size) - 1

  #     assert coordinates.x >= 0 and coordinates.x <= max_coord
  #     assert coordinates.y >= 0 and coordinates.y <= max_coord
  #     assert coordinates.z >= 0 and coordinates.z <= max_coord
  #   end
  # end
end
