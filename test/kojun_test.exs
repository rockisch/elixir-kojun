defmodule KojunTest do
  use ExUnit.Case
  doctest Kojun

  test "greets the world" do
    assert Kojun.hello() == :world
  end
end
