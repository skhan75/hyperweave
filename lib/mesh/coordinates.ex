defmodule Hyperweave.Coordinates do
  @moduledoc """
  Defines a 3D coordinate system for node placement within the mesh.
  """

  defstruct x: 0, y: 0, z: 0

  @type t :: %__MODULE__{
          x: integer(),
          y: integer(),
          z: integer()
        }

  # Utility function to create a new coordinate struct
  @spec new(integer(), integer(), integer()) :: t
  def new(x, y, z) do
    IO.puts("Creating new Coordinates: (#{x}, #{y}, #{z})")
    %__MODULE__{x: x, y: y, z: z}
  end
end
