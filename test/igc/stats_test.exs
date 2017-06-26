defmodule Igc.StatsTest do
  use ExUnit.Case, async: true

  alias Igc.Stats

  test "calculate/1" do
    %Stats{} = stats = File.open!("test/fixtures/2017-06-17-XCT-XXX-01.igc", [:read_ahead, :utf8], fn f ->
      f |> Igc.parse! |> Stats.calculate
    end)

    assert stats == %Stats{
      distance: 99_211,
      duration: 11_044,
      max_altitude: 3_228,
      min_altitude: 1_332,
    }
  end
end
