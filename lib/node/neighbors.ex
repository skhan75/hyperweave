defmodule Hyperweave.Node.Neighbors do
  @moduledoc """
  Manages the neighbors for a node in Hyperweave, organizing connections by direction.
  """

  @type t :: %__MODULE__{
          x_pos: any() | nil,
          x_neg: any() | nil,
          y_pos: any() | nil,
          y_neg: any() | nil,
          z_pos: any() | nil,
          z_neg: any() | nil
        }

  defstruct x_pos: nil, x_neg: nil, y_pos: nil, y_neg: nil, z_pos: nil, z_neg: nil

  # Initializes an empty Neighbors struct
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  # Sets a specific neighbor in the given direction
  @spec set_neighbor(t(), atom(), any()) :: t()
  def set_neighbor(neighbors, direction, neighbor) when direction in [:x_pos, :x_neg, :y_pos, :y_neg, :z_pos, :z_neg] do
    Map.put(neighbors, direction, neighbor)
  end

  # Retrieves a specific neighbor
  @spec get_neighbor(t(), atom()) :: any() | nil
  def get_neighbor(neighbors, direction) when direction in [:x_pos, :x_neg, :y_pos, :y_neg, :z_pos, :z_neg] do
    Map.get(neighbors, direction)
  end
end
