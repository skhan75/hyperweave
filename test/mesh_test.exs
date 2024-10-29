defmodule Hyperweave.MeshTest do
  use ExUnit.Case
  alias Hyperweave.{Mesh, Node, Coordinates}

  @moduletag :mesh_tests

  @tag :initialization
  test "initializes an empty mesh with layer 0" do
    mesh = Mesh.new()
    assert map_size(mesh.nodes) == 0
    assert mesh.layer == 0
  end

  @tag :add_first_node
  test "adds the first node at the center of the mesh in layer 0" do
    mesh = Mesh.new()

    # Add the first node
    mesh = Mesh.add_node(mesh, 1)
    coordinates = Coordinates.new(0, 0, 0)

    # Check that the node is added at the center
    assert Map.has_key?(mesh.nodes, coordinates)
    assert mesh.nodes[coordinates].id == 1
    assert mesh.layer == 0
  end

  @tag :add_node_layer_1
  test "adds nodes to layer 1 and updates mesh.layer accordingly" do
    mesh = Mesh.new()

    # Add the first node
    mesh = Mesh.add_node(mesh, 1)
    assert mesh.layer == 0

    # Add a node to layer 1
    mesh = Mesh.add_node(mesh, 2)
    assert mesh.layer == 1
    assert map_size(mesh.nodes) == 2

    # Verify the second node is in layer 1
    second_node_coord = Enum.find_value(mesh.nodes, fn {coord, node} ->
      if node.id == 2, do: coord, else: nil
    end)
    assert Enum.max([abs(second_node_coord.x), abs(second_node_coord.y), abs(second_node_coord.z)]) == 1
  end

  @tag :neighbor_connections
  test "nodes connect correctly to their neighbors" do
    mesh = Mesh.new()

    # Add the first node
    mesh = Mesh.add_node(mesh, 1)
    coord1 = Coordinates.new(0, 0, 0)

    # Add a second node
    mesh = Mesh.add_node(mesh, 2)
    coord2 = Enum.find_value(mesh.nodes, fn {coord, node} ->
      if node.id == 2, do: coord, else: nil
    end)

    # Ensure nodes are neighbors
    node1_neighbors = Map.from_struct(mesh.nodes[coord1].neighbors)
    node2_neighbors = Map.from_struct(mesh.nodes[coord2].neighbors)

    assert Enum.any?(node1_neighbors, fn {_dir, neighbor} -> neighbor && neighbor.id == 2 end)
    assert Enum.any?(node2_neighbors, fn {_dir, neighbor} -> neighbor && neighbor.id == 1 end)
  end

  @tag :no_premature_expansion
  test "does not expand the mesh prematurely when positions are available" do
    mesh = Mesh.new()

    # Add the first node
    mesh = Mesh.add_node(mesh, 1)
    assert mesh.layer == 0

    # Add a few nodes to layer 1
    mesh = Mesh.add_node(mesh, 2)
    mesh = Mesh.add_node(mesh, 3)
    mesh = Mesh.add_node(mesh, 4)
    assert mesh.layer == 1

    # Total nodes should be 4
    assert map_size(mesh.nodes) == 4

    # Mesh should not expand to layer 2 yet
    assert mesh.layer == 1
  end

  @tag :fill_layer_1
  test "fills layer 1 completely before expanding to layer 2" do
    mesh = Mesh.new()

    # Add nodes to fill layer 1 (total of 26 positions in layer 1)
    mesh =
      Enum.reduce(1..27, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    # Mesh should be at layer 1
    assert mesh.layer == 1
    assert map_size(mesh.nodes) == 27

    # Verify all layer 1 positions are occupied
    layer_1_coords =
      for x <- -1..1, y <- -1..1, z <- -1..1,
          Enum.max([abs(x), abs(y), abs(z)]) == 1,
          do: Coordinates.new(x, y, z)

    assert Enum.all?(layer_1_coords, fn coord -> Map.has_key?(mesh.nodes, coord) end)
  end

  @tag :mesh_expansion
  test "expands the mesh to layer 2 when layer 1 is full" do
    mesh = Mesh.new()

    # Fill layer 1
    mesh =
      Enum.reduce(1..27, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    assert mesh.layer == 1

    # Add a node to trigger expansion to layer 2
    mesh = Mesh.add_node(mesh, 28)
    assert mesh.layer == 2
    assert map_size(mesh.nodes) == 28

    # Verify the new node is in layer 2
    new_node_coord = Enum.find_value(mesh.nodes, fn {coord, node} ->
      if node.id == 28, do: coord, else: nil
    end)

    assert Enum.max([abs(new_node_coord.x), abs(new_node_coord.y), abs(new_node_coord.z)]) == 2
  end

  @tag :correct_node_placement
  test "adds nodes to correct coordinates based on availability, filling layer 0 and 1" do
    mesh = Mesh.new()

    # Add nodes and keep track of their coordinates
    {mesh, coords} =
      Enum.reduce(1..10, {mesh, []}, fn id, {mesh_acc, coords_acc} ->
        mesh_new = Mesh.add_node(mesh_acc, id)
        coord = Enum.find_value(mesh_new.nodes, fn {c, node} ->
          if node.id == id, do: c, else: nil
        end)
        {mesh_new, [coord | coords_acc]}
      end)

    coords = Enum.reverse(coords)

    # Ensure that all coordinates are unique
    assert Enum.uniq(coords) == coords

    # Ensure nodes are added to layers appropriately
    layers = Enum.map(coords, fn coord ->
      Enum.max([abs(coord.x), abs(coord.y), abs(coord.z)])
    end)

    # Since layer 1 has 26 positions, all nodes should be in layer 0 or 1
    assert Enum.all?(layers, fn layer -> layer <= 1 end)
    assert mesh.layer == 1

    # Optionally, verify the layer distribution
    layer_counts = Enum.frequencies(layers)
    assert layer_counts[0] == 1  # One node in layer 0
    assert layer_counts[1] == 9  # Nine nodes in layer 1
  end

  @tag :layer_calculation
  test "calculates mesh.layer correctly based on nodes present" do
    mesh = Mesh.new()
    assert mesh.layer == 0

    # Add nodes to layer 1
    mesh = Mesh.add_node(mesh, 1)
    assert mesh.layer == 0

    mesh = Mesh.add_node(mesh, 2)
    assert mesh.layer == 1

    # Add nodes to fill layer 1
    mesh =
      Enum.reduce(3..27, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    assert mesh.layer == 1

    # Add nodes to layer 2
    mesh = Mesh.add_node(mesh, 28)
    assert mesh.layer == 2

    # Verify mesh.layer matches the highest layer occupied
    max_node_layer =
      mesh.nodes
      |> Map.keys()
      |> Enum.map(fn coord ->
        Enum.max([abs(coord.x), abs(coord.y), abs(coord.z)])
      end)
      |> Enum.max()

    assert mesh.layer == max_node_layer
  end

  @tag :node_count
  test "total node count matches the expected number of added nodes" do
    mesh = Mesh.new()

    # Add 100 nodes
    mesh =
      Enum.reduce(1..100, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    assert map_size(mesh.nodes) == 100
  end

  # @tag :neighbor_integrity
  # test "each node's neighbors are correctly assigned and reciprocal" do
  #   mesh = Mesh.new()

  #   # Add nodes
  #   mesh =
  #     Enum.reduce(1..10, mesh, fn id, acc_mesh ->
  #       Mesh.add_node(acc_mesh, id)
  #     end)

  #   # Verify neighbor connections
  #   Enum.each(mesh.nodes, fn {coord, node} ->
  #     node_neighbors = Map.from_struct(node.neighbors)

  #     Enum.each(node_neighbors, fn {direction, neighbor_node} ->
  #       if neighbor_node do
  #         # Calculate the neighbor's expected coordinate
  #         neighbor_coord = case direction do
  #           :x_pos -> Coordinates.new(coord.x + 1, coord.y, coord.z)
  #           :x_neg -> Coordinates.new(coord.x - 1, coord.y, coord.z)
  #           :y_pos -> Coordinates.new(coord.x, coord.y + 1, coord.z)
  #           :y_neg -> Coordinates.new(coord.x, coord.y - 1, coord.z)
  #           :z_pos -> Coordinates.new(coord.x, coord.y, coord.z + 1)
  #           :z_neg -> Coordinates.new(coord.x, coord.y, coord.z - 1)
  #         end

  #         # Neighbor node should be at the expected coordinate
  #         assert mesh.nodes[neighbor_coord].id == neighbor_node.id

  #         # Neighbor should have a reciprocal connection
  #         opposite_dir = opposite_direction(direction)
  #         neighbor_neighbors = Map.from_struct(neighbor_node.neighbors)
  #         assert neighbor_neighbors[opposite_dir] != nil
  #         assert neighbor_neighbors[opposite_dir].id == node.id
  #       end
  #     end)
  #   end)
  # end

  # Helper function to get the opposite direction
  defp opposite_direction(:x_pos), do: :x_neg
  defp opposite_direction(:x_neg), do: :x_pos
  defp opposite_direction(:y_pos), do: :y_neg
  defp opposite_direction(:y_neg), do: :y_pos
  defp opposite_direction(:z_pos), do: :z_neg
  defp opposite_direction(:z_neg), do: :z_pos

  @tag :layer_filling_order
  test "fills layers in order before expanding to the next layer" do
    mesh = Mesh.new()

    # Add nodes to fill layer 1
    mesh =
      Enum.reduce(1..27, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    # Verify all nodes are in layer 1
    layers = Enum.map(mesh.nodes, fn {coord, _node} ->
      Enum.max([abs(coord.x), abs(coord.y), abs(coord.z)])
    end)

    assert Enum.all?(layers, fn layer -> layer <= 1 end)

    # Add a node to expand to layer 2
    mesh = Mesh.add_node(mesh, 28)
    assert mesh.layer == 2

    # Verify the new node is in layer 2
    new_node_coord = Enum.find_value(mesh.nodes, fn {coord, node} ->
      if node.id == 28, do: coord, else: nil
    end)

    assert Enum.max([abs(new_node_coord.x), abs(new_node_coord.y), abs(new_node_coord.z)]) == 2
  end

  @tag :multiple_layer_expansion
  test "expands to multiple layers as nodes are added" do
    mesh = Mesh.new()

    # Add nodes to fill up to layer 3
    total_nodes = 1 + 26 + 98 + 218  # Nodes in layers 0 to 3
    mesh =
      Enum.reduce(1..total_nodes, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    assert mesh.layer == 3
    assert map_size(mesh.nodes) == total_nodes
  end

  @tag :coordinate_uniqueness
  test "ensures all node coordinates are unique" do
    mesh = Mesh.new()

    # Add nodes
    mesh =
      Enum.reduce(1..50, mesh, fn id, acc_mesh ->
        Mesh.add_node(acc_mesh, id)
      end)

    # Collect all coordinates
    coords = Map.keys(mesh.nodes)

    # Verify uniqueness
    assert Enum.uniq(coords) == coords
  end
end
