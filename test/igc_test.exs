defmodule IgcTest do
  use ExUnit.Case, async: true
  doctest Igc

  describe "parse/1" do
    test "with invalid HFDTE" do
      assert Igc.parse("HFDTE320709\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: \"HFDTE320709\""}

      assert Igc.parse("HFDTEXX0709\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: \"HFDTEXX0709\""}
    end

    test "with trackpoints" do
      igc = """
      HFDTE280709
      B1101355206343N00006198WA0058700558
      B1101455306259N00006295WA0059300556
      B1101555406300N00006061WA0060300576
      """

      {:ok, track} = Igc.parse(igc)

      assert length(track.points) == 3
      assert Enum.map(track.points, &(Map.take(&1, [:latitude]))) ==
        [%{latitude: 52.105716666666666}, %{latitude: 53.10431666666667}, %{latitude: 54.105}]
    end

    test "with invalid trackpoint" do
      assert Igc.parse("HFDTE280709\nB1101355206343X00006198WA0058700558") ==
        {:error, "invalid track point: \"B1101355206343X00006198WA0058700558\""}
    end

    test "trackpoints spanning UTC days" do
      # FIXME
    end
  end
end
