defmodule ClassifierTest do
  use ExUnit.Case
  doctest Classifier

  test "greets the world" do
    assert Classifier.hello() == :world
  end
end
