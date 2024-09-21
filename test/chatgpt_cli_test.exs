defmodule ChatgptCliTest do
  use ExUnit.Case
  doctest ChatgptCli

  test "greets the world" do
    assert ChatgptCli.hello() == :world
  end
end
