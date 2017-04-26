defmodule IgcTest do
  alias Igc.Track

  use ExUnit.Case, async: true
  doctest Igc

  describe "parse/1" do
    test "with IO error" do
      {:ok, io} = StringIO.open("")
      {:ok, _} = StringIO.close(io)

      assert Igc.parse(io) == {:error, :io, :terminated}
    end

    test "with invalid HFDTE" do
      assert Igc.parse("HFDTE320709\nB1101355206343N00006198WA0058700558") ==
        {:error, :invalid_igc, "invalid date: \"HFDTE320709\""}

      assert Igc.parse("HFDTEXX0709\nB1101355206343N00006198WA0058700558") ==
        {:error, :invalid_igc, "invalid date: \"HFDTEXX0709\""}
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
      assert Enum.map(track.points, &(Map.take(&1, [:latitude, :datetime]))) ==
        [
          %{datetime: ~N[2009-07-28 11:01:35], latitude: 52.105716666666666},
          %{datetime: ~N[2009-07-28 11:01:45], latitude: 53.10431666666667},
          %{datetime: ~N[2009-07-28 11:01:55], latitude: 54.105}
        ]
    end

    test "with invalid trackpoint" do
      assert Igc.parse("HFDTE280709\nB1101355206343X00006198WA0058700558") ==
        {:error, :invalid_igc, "invalid track point: \"B1101355206343X00006198WA0058700558\""}
    end

    test "trackpoints spanning UTC days" do
      # FIXME
    end

    test "ignores unknown lines" do
      assert {:ok, %Track{}} = Igc.parse("HFDTE280709\nHFWTF\nB1101355206343N00006198WA0058700558")
    end
  end
end
