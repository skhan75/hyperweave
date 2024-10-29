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
          }
        }

  defstruct [
    :id,
    :coordinates,
    :neighbors,
    :state,
    :data_cache,
    :uptime,
    :metrics,
    :finger_table
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
      metrics: %{messages_sent: 0, messages_received: 0}
    }
  end

  # Adds a neighbor to the node
  @spec add_neighbor(t(), any(), atom()) :: t()
  def add_neighbor(node, neighbor, direction) do
    %{node | neighbors: Neighbors.set_neighbor(node.neighbors, direction, neighbor)}
  end
end
