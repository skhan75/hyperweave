defmodule Hyperweave.Mesh.HilbertSpaceFillingCurveTest do
  use ExUnit.Case
  alias Hyperweave.Mesh.HilbertSpaceFillingCurve
  alias Hyperweave.Coordinates

  doctest Hyperweave.Mesh.HilbertSpaceFillingCurve

  @moduletag :hilbert_curve

  test "hilbert_3d function with order 1" do
    order = 1

    expected_results = %{
      0 => Coordinates.new(0, 0, 0),
      1 => Coordinates.new(0, 0, 1),
      2 => Coordinates.new(0, 1, 1),
      3 => Coordinates.new(0, 1, 0),
      4 => Coordinates.new(1, 1, 0),
      5 => Coordinates.new(1, 1, 1),
      6 => Coordinates.new(1, 0, 1),
      7 => Coordinates.new(1, 0, 0)
    }

    for {index, expected_coord} <- expected_results do
      result = HilbertSpaceFillingCurve.hilbert_3d(order, index)
      assert result == expected_coord,
             "For index #{index}, expected #{inspect(expected_coord)}, got #{inspect(result)}"
    end
  end

  test "hilbert_3d function with boundary indices for order 2" do
    order = 2
    max_index = trunc(:math.pow(2, 3 * order)) - 1  # 2^(3*2) - 1 = 63

    # Test minimum index
    min_result = HilbertSpaceFillingCurve.hilbert_3d(order, 0)
    assert min_result == Coordinates.new(0, 0, 0),
      "For index 0, expected (0, 0, 0), got #{inspect(min_result)}"

    # # Test maximum index
    max_result = HilbertSpaceFillingCurve.hilbert_3d(order, max_index)
    expected_max_coord = Coordinates.new(3, 0, 0)  # Corrected expected coordinate
    assert max_result == expected_max_coord,
      "For index #{max_index}, expected #{inspect(expected_max_coord)}, got #{inspect(max_result)}"
  end

  test "hilbert_3d function with invalid inputs" do
    # Negative index
    assert_raise ArgumentError, fn ->
      HilbertSpaceFillingCurve.hilbert_3d(2, -1)
    end

    # Negative order
    assert_raise ArgumentError, fn ->
      HilbertSpaceFillingCurve.hilbert_3d(-1, 0)
    end

    # Index out of range
    order = 1
    invalid_index = 8  # For order 1, valid indices are 0 to 7
    assert_raise ArgumentError, fn ->
      HilbertSpaceFillingCurve.hilbert_3d(order, invalid_index)
    end
  end

end
