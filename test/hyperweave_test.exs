defmodule HyperweaveTest do
  use ExUnit.Case
  doctest Hyperweave

  test "greets the world" do
    assert Hyperweave.hello() == :world
  end
end
