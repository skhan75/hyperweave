defmodule Hyperweave.Mesh.HilbertSpaceFillingCurve do
  @moduledoc """
  Provides methods for converting between 1D Hilbert indices and 3D coordinates
  within the mesh space, optimizing for spatial locality.
  """

  alias Hyperweave.Coordinates
  import Bitwise

  @doc """
  Converts a Hilbert index into a 3D coordinate based on the specified order.

  ## Parameters
  - `order`: The order of the Hilbert curve, which determines the size of the coordinate space.
  - `index`: The Hilbert index (1D) to be converted into a 3D coordinate.

  ## Returns
  - A `Coordinates` struct containing the `x`, `y`, and `z` coordinates.

  ## Example
      iex> Hyperweave.Mesh.HilbertSpaceFillingCurve.hilbert_3d(16, 123456)
      %Coordinates{x: 5, y: 15, z: 3}
  """
  @spec hilbert_3d(integer(), integer()) :: Coordinates.t()
  def hilbert_3d(order, index) do
    {x, y, z} = hilbert_index_to_3d(order, index)
    Coordinates.new(x, y, z)
  end

  # The actual conversion function from a Hilbert index to a 3D coordinate.
  defp hilbert_index_to_3d(order, index) do
    # Initialize the coordinates and the direction of movement
    {x, y, z} = {0, 0, 0}
    n = Integer.pow(2, order)
    half_n = n / 2

    # Start from the index and map down to coordinates
    index = :binary.decode_unsigned(:erlang.term_to_binary(index))

    {x, y, z} = index_to_coordinate(index, order, x, y, z, half_n)
    {x, y, z}
  end

  # Recursive function to convert Hilbert index to coordinates
  defp index_to_coordinate(0, _, x, y, z, _), do: {x, y, z}
  defp index_to_coordinate(index, order, x, y, z, half_n) do
    # Determine cube index in each axis
    a = (index &&& 4) >>> 2
    b = (index &&& 2) >>> 1
    c = index &&& 1

    # Perform bit rotations and transformations based on current cube index
    {x, y, z} = rotate(x, y, z, a, b, c)
    {x, y, z} = {x + a * half_n, y + b * half_n, z + c * half_n}

    # Calculate new position and continue recursion
    index_to_coordinate(div(index, 8), order - 1, x, y, z, half_n / 2)
  end

  # Rotate coordinates based on current bits
  defp rotate(x, y, z, a, b, c) do
    cond do
      b == 0 and a == 1 ->
        {z, y, x}

      b == 0 ->
        {x, y, z}

      a == 1 ->
        {x, y, z}

      true ->
        {y, z, x}
    end
  end
end
