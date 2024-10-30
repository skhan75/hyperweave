defmodule Hyperweave.Mesh do
  @moduledoc """
  Manages the 3D Mesh structure of the Hyperweave network.
  """

  alias Hyperweave.{Node, Coordinates}

  defstruct nodes: %{}, layer: 0

  @type t :: %__MODULE__{
          nodes: %{optional(Coordinates.t()) => Node.t()},
          layer: integer()
        }

  @doc """
  Initializes a new Mesh starting with layer 0.
  """
  @spec new() :: t()
  def new() do
    IO.puts("Initializing a new Mesh...")
    %__MODULE__{
      nodes: %{},
      layer: 0
    }
  end

  @doc """
  Adds a node to the mesh with the given ID.
  """
  @spec add_node(t(), any()) :: t()
  def add_node(%__MODULE__{} = mesh, id) do
    IO.puts("\nAttempting to add node with ID #{id}...")

    if is_empty?(mesh) do
      IO.puts("Mesh is empty. Adding first node at coordinates (0, 0, 0).")
      coordinates = Coordinates.new(0, 0, 0)
      new_node = Node.new(id, coordinates)
      updated_mesh = %{mesh | nodes: Map.put(mesh.nodes, coordinates, new_node)}
      updated_mesh = connect_neighbors(updated_mesh, new_node, coordinates)
      updated_mesh
    else
      {mesh_with_spot, {:ok, coordinates}} = find_open_spot(mesh)
      IO.puts("Found open spot at coordinates #{inspect(coordinates)} for node #{id}.")

      new_node = Node.new(id, coordinates)
      updated_nodes = Map.put(mesh_with_spot.nodes, coordinates, new_node)

      # Calculate the layer of the new node
      node_layer = Enum.max([abs(coordinates.x), abs(coordinates.y), abs(coordinates.z)])

      # Update the mesh layer if necessary
      new_mesh_layer = max(mesh_with_spot.layer, node_layer)

      updated_mesh = %{mesh_with_spot | nodes: updated_nodes, layer: new_mesh_layer}
      updated_mesh = connect_neighbors(updated_mesh, new_node, coordinates)
      updated_mesh
    end
  end

  @doc """
  Checks if the mesh is empty (no nodes).
  """
  @spec is_empty?(t()) :: boolean()
  def is_empty?(%__MODULE__{nodes: nodes}) do
    map_size(nodes) == 0
  end

  # Finds an open slot in the mesh layers up to mesh.layer
  defp find_open_spot(%__MODULE__{nodes: nodes, layer: mesh_layer} = mesh) do
    IO.puts("Searching for open spot in layers up to #{mesh_layer}...")

    # Start searching from layer 1 up to mesh.layer
    layer_range = if mesh_layer == 0, do: [1], else: 1..mesh_layer

    candidate_coords =
      layer_range
      |> Enum.flat_map(fn layer ->
        # Generate all possible coordinates in the current layer
        for x <- -layer..layer,
            y <- -layer..layer,
            z <- -layer..layer,
            Enum.max([abs(x), abs(y), abs(z)]) == layer,
            do: Coordinates.new(x, y, z)
      end)
      |> Enum.filter(fn coord -> Map.get(nodes, coord) == nil end)
      |> Enum.sort_by(fn coord ->
        distance = abs(coord.x) + abs(coord.y) + abs(coord.z)
        distance
      end)

    case candidate_coords do
      [] ->
        IO.puts("No open spot found in layers up to #{mesh_layer}. Expanding mesh...")
        expanded_mesh = expand(mesh)
        find_open_spot(expanded_mesh)

      [coord | _] ->
        IO.puts("Found open spot at coordinates #{inspect(coord)}.")
        {mesh, {:ok, coord}}
    end
  end

  # Expands the mesh by increasing the layer
  defp expand(%__MODULE__{layer: layer} = mesh) do
    new_layer = layer + 1
    IO.puts("Expanding mesh to new layer #{new_layer}.")
    %{mesh | layer: new_layer}
  end

  # Corrected connect_neighbors/3 function
  defp connect_neighbors(mesh, _node, coord) do
    # Connect to all the 6 neighbors on principal axises
    # TODO - We could connect to all 26 neigbors in future for increased connectivity and robust network
    # The following formula gives each of the 27 neighboring coordinates - (x+dx,y+dy,z+dz) where dx,dy,dz∈{−1,0,1}
    directions = [
      {:x_pos, Coordinates.new(coord.x + 1, coord.y, coord.z)},
      {:x_neg, Coordinates.new(coord.x - 1, coord.y, coord.z)},
      {:y_pos, Coordinates.new(coord.x, coord.y + 1, coord.z)},
      {:y_neg, Coordinates.new(coord.x, coord.y - 1, coord.z)},
      {:z_pos, Coordinates.new(coord.x, coord.y, coord.z + 1)},
      {:z_neg, Coordinates.new(coord.x, coord.y, coord.z - 1)}
    ]

    updated_nodes = Enum.reduce(directions, mesh.nodes, fn {direction, neighbor_coord}, acc_nodes ->
      node = Map.get(acc_nodes, coord)
      neighbor_node = Map.get(acc_nodes, neighbor_coord)

      if neighbor_node do
        # Update the node's neighbors with neighbor's coordinates
        updated_node = Node.add_neighbor(node, neighbor_coord, direction)

        # Update the neighbor's neighbors with node's coordinates
        opposite_dir = opposite_direction(direction)
        updated_neighbor = Node.add_neighbor(neighbor_node, coord, opposite_dir)

        # Logging the updates
        IO.puts("Connecting node #{node.id} at #{inspect(coord)}")
        IO.puts("  Direction: #{direction}")
        IO.puts("  Neighbor node #{neighbor_node.id} at #{inspect(neighbor_coord)}")
        IO.puts("  Node #{node.id} neighbors after update: #{inspect(updated_node.neighbors)}")
        IO.puts("  Neighbor node #{neighbor_node.id} neighbors after update: #{inspect(updated_neighbor.neighbors)}\n")

        acc_nodes
        |> Map.put(coord, updated_node)
        |> Map.put(neighbor_coord, updated_neighbor)
      else
        acc_nodes
      end
    end)

    %{mesh | nodes: updated_nodes}
  end

  # Maps each direction to its opposite
  defp opposite_direction(:x_pos), do: :x_neg
  defp opposite_direction(:x_neg), do: :x_pos
  defp opposite_direction(:y_pos), do: :y_neg
  defp opposite_direction(:y_neg), do: :y_pos
  defp opposite_direction(:z_pos), do: :z_neg
  defp opposite_direction(:z_neg), do: :z_pos

end
