defmodule Hyperweave.Node.Neighbors do
  @moduledoc """
  Manages the neighbors for a node in Hyperweave, organizing connections by direction.
  """

  alias Hyperweave.Coordinates

  @type t :: %__MODULE__{
          x_pos: Coordinates.t() | nil,
          x_neg: Coordinates.t() | nil,
          y_pos: Coordinates.t() | nil,
          y_neg: Coordinates.t() | nil,
          z_pos: Coordinates.t() | nil,
          z_neg: Coordinates.t() | nil
        }

  defstruct x_pos: nil, x_neg: nil, y_pos: nil, y_neg: nil, z_pos: nil, z_neg: nil

  # Initializes an empty Neighbors struct
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  # Sets a specific neighbor in the given direction
  @spec set_neighbor(t(), atom(), Coordinates.t()) :: t()
  def set_neighbor(neighbors, direction, neighbor_coord) when direction in [:x_pos, :x_neg, :y_pos, :y_neg, :z_pos, :z_neg] do
    Map.put(neighbors, direction, neighbor_coord)
  end

  # Retrieves a specific neighbor coordinate
  @spec get_neighbor(t(), atom()) :: Coordinates.t() | nil
  def get_neighbor(neighbors, direction) when direction in [:x_pos, :x_neg, :y_pos, :y_neg, :z_pos, :z_neg] do
    Map.get(neighbors, direction)
  end
end
