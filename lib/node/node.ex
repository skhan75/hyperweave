defmodule Hyperweave.Node do
  @moduledoc """
  Defines the core structure of a Node within Hyperweave, including attributes, neighbors,
  and data caching.
  """

  alias Hyperweave.Node.Neighbors
  alias Hyperweave.Coordinates

  @type t :: %__MODULE__{
          id: any(),
          coordinates: Coordinates.t(),
          neighbors: Neighbors.t(),
          finger_table: map(),
          state: :active | :inactive,
          data_cache: map(),
          uptime: non_neg_integer(),
          metrics: %{
            messages_sent: non_neg_integer(),
            messages_received: non_neg_integer()
          },
          last_heartbeat: integer() | nil
        }

  defstruct [
    :id,
    :coordinates,
    :neighbors,
    :finger_table,
    :state,
    :data_cache,
    :uptime,
    :metrics,
    last_heartbeat: nil
  ]

  # Initialize the new node with default attributes
  @spec new(any(), Coordinates.t()) :: t()
  def new(id, coordinates = %Coordinates{}) do
    %__MODULE__{
      id: id,
      coordinates: coordinates,
      finger_table: %{},
      neighbors: Neighbors.new(),
      state: :active,
      data_cache: %{},
      uptime: 0,
      metrics: %{messages_sent: 0, messages_received: 0},
      last_heartbeat: System.system_time(:second) # Set the initial last_heartbeat to the current timestamp
    }
  end

  # Adds a neighbor to the node
  @spec add_neighbor(t(), Coordinates.t(), atom()) :: t()
  def add_neighbor(node, neighbor_coord, direction) do
    %{node | neighbors: Neighbors.set_neighbor(node.neighbors, direction, neighbor_coord)}
  end

  # Removes a neighbor from the node
  @spec remove_neighbor(t(), atom()) :: t()
  def remove_neighbor(node, direction) do
    updated_neighbors = Neighbors.set_neighbor(node.neighbors, direction, nil)
    %{node | neighbors: updated_neighbors}
  end
end
