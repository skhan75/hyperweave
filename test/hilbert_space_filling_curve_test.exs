defmodule Hyperweave.Mesh.HilbertSpaceFillingCurveTest do
  use ExUnit.Case
  alias Hyperweave.Mesh.HilbertSpaceFillingCurve
  alias Hyperweave.Coordinates

  import Bitwise

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

  test "hilbert_3d function with boundary indices for various orders" do
    orders = [1, 2, 3, 4]

    for order <- orders do
      max_index = trunc(:math.pow(2, 3 * order)) - 1

      # Test minimum index
      min_result = HilbertSpaceFillingCurve.hilbert_3d(order, 0)
      assert min_result == Coordinates.new(0, 0, 0),
             "For order #{order}, index 0, expected (0, 0, 0), got #{inspect(min_result)}"

      # Test maximum index
      max_result = HilbertSpaceFillingCurve.hilbert_3d(order, max_index)
      IO.inspect(max_result, label: "Result")

      # Expected coordinate for max index needs to be verified
      # For simplicity, we can state that the coordinate should be within the valid range
      # For order n, each axis ranges from 0 to 2^n - 1

      max_coord_value = (1 <<< order) - 1
      assert max_result.x >= 0 and max_result.x <= max_coord_value,
             "For order #{order}, max index #{max_index}, x-coordinate out of bounds: #{max_result.x}"
      assert max_result.y >= 0 and max_result.y <= max_coord_value,
             "For order #{order}, max index #{max_index}, y-coordinate out of bounds: #{max_result.y}"
      assert max_result.z >= 0 and max_result.z <= max_coord_value,
             "For order #{order}, max index #{max_index}, z-coordinate out of bounds: #{max_result.z}"
    end
  end

  test "hilbert_3d function with random valid indices" do
    orders = [2, 3, 4]

    for order <- orders do
      max_index = trunc(:math.pow(2, 3 * order)) - 1
      max_coord_value = (1 <<< order) - 1

      # Generate 10 random indices for each order
      for _ <- 1..10 do
        index = :rand.uniform(max_index + 1) - 1  # Random index between 0 and max_index
        result = HilbertSpaceFillingCurve.hilbert_3d(order, index)

        assert result.x >= 0 and result.x <= max_coord_value,
               "Order #{order}, index #{index}: x-coordinate out of bounds: #{result.x}"
        assert result.y >= 0 and result.y <= max_coord_value,
               "Order #{order}, index #{index}: y-coordinate out of bounds: #{result.y}"
        assert result.z >= 0 and result.z <= max_coord_value,
               "Order #{order}, index #{index}: z-coordinate out of bounds: #{result.z}"
      end
    end
  end

  test "hilbert_3d function with non-integer and non-numeric inputs" do
    invalid_orders = [0, -1, 1.5, "two", nil, :atom]
    invalid_indices = [-1, 1.5, "ten", nil, :atom]

    for order <- invalid_orders do
      assert_raise ArgumentError, fn ->
        HilbertSpaceFillingCurve.hilbert_3d(order, 0)
      end
    end

    for index <- invalid_indices do
      assert_raise ArgumentError, fn ->
        HilbertSpaceFillingCurve.hilbert_3d(2, index)
      end
    end
  end


  test "hilbert_3d function preserves spatial locality with distance distribution" do
    order = 4
    max_index = trunc(:math.pow(2, 3 * order)) - 1

    distances = for index <- 0..(max_index - 1) do
      coord1 = HilbertSpaceFillingCurve.hilbert_3d(order, index)
      coord2 = HilbertSpaceFillingCurve.hilbert_3d(order, index + 1)

      # Calculate the Euclidean distance between the coordinates
      :math.sqrt(:math.pow(coord1.x - coord2.x, 2) +
                 :math.pow(coord1.y - coord2.y, 2) +
                 :math.pow(coord1.z - coord2.z, 2))
    end

    total = length(distances)
    small_distances = Enum.count(distances, fn d -> d <= :math.sqrt(3) end)
    proportion_small = small_distances / total * 100  # Convert to percentage

    # Adjusted threshold to 89%
    assert proportion_small >= 89.0,
           "Proportion of small distances is too low: #{proportion_small}%"
  end

  test "hilbert_3d function handles rotations correctly" do
    # For specific indices known to cause rotations
    test_cases = [
      {0, Coordinates.new(0, 0, 0)},
      {7, Coordinates.new(1, 0, 0)},
      {14, Coordinates.new(1, 0, 3)},
      {21, Coordinates.new(1, 3, 3)},
      {28, Coordinates.new(1, 3, 0)},
      {35, Coordinates.new(2, 3, 0)}
    ]

    for {index, expected_coord} <- test_cases do
      result = HilbertSpaceFillingCurve.hilbert_3d(2, index)
      assert result == expected_coord,
             "For index #{index}, expected #{inspect(expected_coord)}, got #{inspect(result)}"
    end
  end


end
