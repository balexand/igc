defmodule Igc.StatsTest do
  use ExUnit.Case, async: true

  alias Igc.Stats

  test "calculate/1" do
    %Stats{} = stats =
      "test/fixtures/2017-06-17-XCT-XXX-01.igc"
      |> File.read!
      |> Igc.parse!
      |> Stats.calculate

    assert stats == %Stats{
      distance: 99_211,
      max_climb: 5.548387096774604
    }
  end
end
