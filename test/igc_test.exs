defmodule IgcTest do
  alias Igc.{Track, TrackPoint}

  use ExUnit.Case, async: true
  doctest Igc

  @valid_date "HFDTE280709\n"

  @valid_points """
  B1101355206343N00006198WA0058700558
  B1101455306259N00006295WA0059300556
  """

  @valid_igc @valid_date <> @valid_points

  describe "parse/1" do
    test "with valid data" do
      {:ok, track} = Igc.parse(@valid_igc)

      assert length(track.points) == 2
      assert track.points == [
        %TrackPoint{datetime: ~N[2009-07-28 11:01:35], gps_altitude: 558, latitude: 52.105716666666666, longitude: -0.1033, pressure_altitude: 587, validity: "A"},
        %TrackPoint{datetime: ~N[2009-07-28 11:01:45], gps_altitude: 556, latitude: 53.10431666666667, longitude: -0.10491666666666667, pressure_altitude: 593, validity: "A"}
      ]

      assert %TrackPoint{latitude: 52.105716666666666} = track.take_off
      assert %TrackPoint{latitude: 53.10431666666667}  = track.landing
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
      assert {:ok, %Track{}} = Igc.parse("HFWTF\n" <> @valid_igc)
    end

    test "with invalid HFDTE" do
      assert Igc.parse("HFDTE320709\n#{@valid_points}") ==
        {:error, "invalid date: \"HFDTE320709\""}

      assert Igc.parse("HFDTEXX0709\n#{@valid_points}") ==
        {:error, "invalid date: \"HFDTEXX0709\""}

      assert Igc.parse("HFDTE3107090\n#{@valid_points}") ==
        {:error, "invalid date: \"HFDTE3107090\""}
    end

    test "with invalid trackpoint" do
      assert Igc.parse(@valid_igc <> "B1101355206343X00006198WA0058700558") ==
        {:error, "invalid track point: \"B1101355206343X00006198WA0058700558\""}
    end

    test "with single point" do
      single_point =
        @valid_points
        |> String.split("\n")
        |> List.first

      assert Igc.parse(@valid_date <> single_point) ==
        {:error, "must contain at least 2 points"}
    end

    test "without date" do
      assert Igc.parse(@valid_points) ==
        {:error, "file must include date"}
    end
  end
end
