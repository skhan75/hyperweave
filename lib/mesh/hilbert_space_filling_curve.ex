defmodule Hyperweave.Mesh.HilbertSpaceFillingCurve do
  @moduledoc """
  Provides methods for converting between 1D Hilbert indices and 3D coordinates
  within the mesh space, optimizing for spatial locality.

  The Hilbert space-filling curve is a continuous fractal curve that visits every point in a
  grid space without crossing itself. It preserves spatial locality better than other curves
  like the Morton curve, making it ideal for mapping node IDs to coordinates in a mesh network.
  """

  alias Hyperweave.Coordinates
  import Bitwise  # Import bitwise operators for bit manipulation

  @doc """
  Converts a Hilbert index into a 3D coordinate based on the specified order.

  ## Parameters

    - `order`: The order of the Hilbert curve, which determines the size of the coordinate space.
      - The number of divisions along each axis is `2^order`.
    - `index`: The Hilbert index (1D integer) to be converted into a 3D coordinate.
      - Must be in the range `[0, 2^(3 * order) - 1]`.

  ## Returns

    - A `Coordinates` struct containing the `x`, `y`, and `z` coordinates.

  ## Example

      iex> Hyperweave.Mesh.HilbertSpaceFillingCurve.hilbert_3d(2, 10)
      %Hyperweave.Coordinates{x: 0, y: 1, z: 3}

  """
  @spec hilbert_3d(integer(), integer()) :: Coordinates.t()
  def hilbert_3d(order, index) when is_integer(order) and order > 0 and is_integer(index) and index >= 0 do
    max_index = trunc(:math.pow(2, 3 * order)) - 1

    if index > max_index do
      raise ArgumentError,
            "Index #{index} is out of range for order #{order}. Valid indices are from 0 to #{max_index}."
    end

    # Convert the Hilbert index to coordinates
    {x, y, z} = hilbert_index_to_point(index, order)

    # Return the coordinates as a struct
    Coordinates.new(x, y, z)
  end

  def hilbert_3d(_order, _index) do
    raise ArgumentError,
          "Invalid order or index. Order must be a positive integer, and index must be a non-negative integer within the valid range."
  end

  # Converts a Hilbert index to 3D coordinates using recursive decoding
  defp hilbert_index_to_point(index, order) do
    # Total number of bits for the Hilbert index
    total_bits = 3 * order

    # Initial coordinates and orientation
    coords = {0, 0, 0}
    rotation = {0, 0, 0}

    # Recursive decoding of the Hilbert index
    hilbert_integer_to_coordinates(index, total_bits, coords, rotation)
  end

  # Recursive function to decode Hilbert index to coordinates
  defp hilbert_integer_to_coordinates(index, bits, coords, rotation) do
    if bits == 0 do
      coords
    else
      # Decrease bits by 3 for the next recursion
      new_bits = bits - 3

      # Create a mask to extract the highest three bits
      mask = 7 <<< new_bits  # 7 in binary is 111

      # Extract the digit corresponding to the current bits
      digit = (index &&& mask) >>> new_bits  # Get the current digit (3 bits)

      # Rotate and flip the digit to get the next coordinates and orientation
      {new_coords, new_rotation} = hilbert_decode_step(digit, coords, rotation, new_bits)

      # Continue with the remaining bits
      hilbert_integer_to_coordinates(index, new_bits, new_coords, new_rotation)
    end
  end

  # Decode a single step of the Hilbert curve
  defp hilbert_decode_step(digit, {x, y, z}, {rx, ry, rz}, bits) do
    # Calculate the size of the current cube
    n = 1 <<< div(bits, 3)

    # Get coordinate increments and new rotation from the lookup table
    {dx, dy, dz, new_rx, new_ry, new_rz} = hilbert_lookup_table(digit, rx, ry, rz)

    # Update coordinates
    new_x = x + dx * n
    new_y = y + dy * n
    new_z = z + dz * n

    # Update rotation
    new_rotation = {new_rx, new_ry, new_rz}

    {{new_x, new_y, new_z}, new_rotation}
  end

  # Lookup table for Hilbert curve digit decoding
  defp hilbert_lookup_table(digit, rx, ry, rz) do
    # This table defines how each digit affects the coordinates and rotation
    # Based on the current orientation (rx, ry, rz) and the digit
    case {digit, rx, ry, rz} do
      {0, _, _, _} -> {0, 0, 0, ry, rz, rx}
      {1, _, _, _} -> {0, 0, 1, rx, ry, rz}
      {2, _, _, _} -> {0, 1, 1, rx, ry, rz}
      {3, _, _, _} -> {0, 1, 0, ry, rz, rx}
      {4, _, _, _} -> {1, 1, 0, ry, rz, rx}
      {5, _, _, _} -> {1, 1, 1, rx, ry, rz}
      {6, _, _, _} -> {1, 0, 1, rx, ry, rz}
      {7, _, _, _} -> {1, 0, 0, ry, rz, rx}
      _ -> {0, 0, 0, rx, ry, rz}  # Default case (should not occur)
    end
  end
end
