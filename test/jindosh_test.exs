defmodule JindoshTest do
  use ExUnit.Case
  doctest Jindosh

  test "greets the world" do
    assert Jindosh.hello() == :world
  end
end
