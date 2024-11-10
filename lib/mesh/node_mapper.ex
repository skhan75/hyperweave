defmodule Hyperweave.Mesh.NodeMapper do
  @moduledoc """
  Responsible for adding nodes to the mesh and mapping node IDs to 3D coordinates.
  Utilizes hashing and space-filling curves (like Hilbert Curve) for efficient and locality-aware placement.
  """

  alias Hyperweave.{Node, Coordinates, Mesh}
  alias Mesh.{HilbertSpaceFillingCurve}

  @space_size 16 # Assume a manageable space for demo; can be expanded

  @doc """
  Creates a new node with a unique coordinate calculated based on the node ID.
  """
  @spec create_node(any(), Coordinates.t()) :: Node.t()
  def create_node(node_id, existing_coordinates) do
    coordinate = calculate_spatially_optimal_coordinate(node_id, existing_coordinates)
    Node.new(node_id, coordinate)
  end

  # Calculates the spatially optimal 3D coordinate based on a Space Filling Curve.
  def calculate_spatially_optimal_coordinate(node_id, existing_coordinates) do
    # Existing coordinates: a MapSet or list of occupied Coordinates

    # Hash the node ID using SHA-256 and convert the result to an integer
    hashed_id = :crypto.hash(:sha256, to_string(node_id))
    numeric_id = :binary.decode_unsigned(hashed_id)

    # Calculate the maximum Hilbert index based on the space size
    max_hilbert_index = Integer.pow(2, 3 * @space_size) - 1  # Total indices: 0 to max_hilbert_index

    # Map the hashed value to the available range of Hilbert indices
    h_index = rem(numeric_id, max_hilbert_index + 1)  # Include max_hilbert_index in the range

    # Attempt to find an unoccupied coordinate
    find_unoccupied_coordinate(h_index, max_hilbert_index, existing_coordinates)
  end

  defp find_unoccupied_coordinate(h_index, max_hilbert_index, existing_coordinates) do
    # Start from the initial Hilbert index and search for an unoccupied coordinate
    Enum.reduce_while(0..max_hilbert_index, nil, fn offset, _acc ->
      # Calculate the new index by adding the offset (wrap around using rem)
      new_index = rem(h_index + offset, max_hilbert_index + 1)

      # Convert the index to coordinates
      coord = HilbertSpaceFillingCurve.hilbert_3d(@space_size, new_index)

      # Check if the coordinate is unoccupied
      if MapSet.member?(existing_coordinates, coord) do
        # Coordinate is occupied, continue searching
        {:cont, nil}
      else
        # Found unoccupied coordinate, stop the search
        {:halt, coord}
      end
    end)
  end


end
