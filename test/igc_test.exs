defmodule IgcTest do
  alias Igc.Track

  use ExUnit.Case, async: true
  doctest Igc

  describe "parse/1" do
    test "with valid data" do
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

    test "with trackpoints spanning UTC days" do
      igc = """
      HFDTE250815
      B2359574235690N11052753WA027270289600604673030-0085
      B2359584235696N11052748WA027260289500604721029-0085
      B2359594235702N11052744WA027250289400604721021-0091
      B0000004235709N11052741WA027240289300604631014-0059
      B0000014235716N11052739WA027230289200604556009-0073
      B0000024235722N11052738WA027220289100604451006-0085
      """

      {:ok, track} = Igc.parse(igc)
      assert Enum.map(track.points, &(&1.datetime)) ==
        [
          ~N[2015-08-25 23:59:57],
          ~N[2015-08-25 23:59:58],
          ~N[2015-08-25 23:59:59],
          ~N[2015-08-26 00:00:00],
          ~N[2015-08-26 00:00:01],
          ~N[2015-08-26 00:00:02],
        ]
    end

    test "with unknown lines" do
      assert {:ok, %Track{}} = Igc.parse("HFDTE280709\nHFWTF\nB1101355206343N00006198WA0058700558")
    end

    test "with invalid HFDTE" do
      assert Igc.parse("HFDTE320709\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: \"HFDTE320709\""}

      assert Igc.parse("HFDTEXX0709\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: \"HFDTEXX0709\""}

      assert Igc.parse("HFDTE3107090\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: \"HFDTE3107090\""}
    end

    test "with invalid trackpoint" do
      assert Igc.parse("HFDTE280709\nB1101355206343X00006198WA0058700558") ==
        {:error, "invalid track point: \"B1101355206343X00006198WA0058700558\""}
    end

    test "without date" do
      assert Igc.parse("B1101355206343N00006198WA0058700558") ==
        {:error, "file must include date"}
    end
  end
end
