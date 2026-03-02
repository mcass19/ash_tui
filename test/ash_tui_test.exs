defmodule AshTuiTest do
  use ExUnit.Case
  doctest AshTui

  test "greets the world" do
    assert AshTui.hello() == :world
  end
end
