defmodule Hyperweave.Mesh.NodeMapper do
  @moduledoc """
  Responsible for adding nodes to the mesh and mapping node IDs to 3D coordinates.
  Utilizes hashing and space-filling curves (like Hilbert Curve) for efficient and locality-aware placement.
  """

  alias Hyperweave.{Node, Coordinates}

  @space_size 16 # Assume a manageable space for demo; can be expanded

  @doc """
  Creates a new node with a unique coordinate calculated based on the node ID.
  """
  @spec create_node(any()) :: Node.t()
  def create_node(node_id) do
    coordinate = calculate_spatially_optimal_coordinate(node_id)
    Node.new(node_id, coordinate)
  end

  # Calculates the spatially optimal 3D coordinate based on a Space Filling Curve.
  def calculate_spatially_optimal_coordinate(node_id) do
     # Hash the node ID using SHA-256 and convert the result to an integer
    hashed_id = :crypto.hash(:sha256, to_string(node_id))
    numeric_id = :binary.decode_unsigned(hashed_id)

    # Calculate maximum Hilbert index based on 3D space size
    max_hilbert_index = Integer.pow(2, 3 * @space_size)

    # Map the hashed value to the available range of Hilbert indices
    h_index = rem(numeric_id, max_hilbert_index)

    # Use the Hilbert Curve to convert the hash into a 3D coordinate
    hilbert_to_3d(hashed_id, @space_size)
    # Returns a Coordinates struct with the 3D coordinates for spatial locality.
  end


   # Converts a Hilbert curve index to a 3D coordinate.
  @spec hilbert_to_3d(integer(), integer()) :: Coordinates.t()
  defp hilbert_to_3d(h_index, order) do
    # Call the Hilbert curve module to convert index to 3D coordinates
    {x, y, z} = Hyperweave.SpaceFillingCurve.hilbert_3d(order, h_index)
    Coordinates.new(x, y, z)
  end
end
