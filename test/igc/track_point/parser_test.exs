defmodule Igc.TrackPoint.ParserTest do
  alias Igc.TrackPoint
  import Igc.TrackPoint.Parser, only: [parse: 1]

  use ExUnit.Case, async: true
  doctest TrackPoint

  # Example from http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/
  @defaults %{
    time: "110135",
    latitude: "5206343N",
    longitude: "00006198W",
    validity: "A",
    pressure_altitude: "00587",
    gps_altitude: "00558"
  }

  defp format(t \\ []) do
    t = Enum.into(t, @defaults)

    "B#{t.time}#{t.latitude}#{t.longitude}#{t.validity}#{t.pressure_altitude}#{t.gps_altitude}"
  end

  test "format defaults" do
    assert format() == "B1101355206343N00006198WA0058700558"
  end

  describe "parse" do
    test "successfully" do
      assert parse("B1101355206343N00006198WA0058700558") ==
        {:ok, {
          %Igc.TrackPoint{
            latitude: 52.105716666666666,
            longitude: -0.1033,
            validity: "A",
            pressure_altitude: 587,
            gps_altitude: 558
          }, ~T[11:01:35]
        }}
    end

    test "invalid format" do
      assert parse("B1101355206343X00006198WA0058700558") ==
        {:error, "invalid track point: \"B1101355206343X00006198WA0058700558\""}
    end
    test "with S latitude" do
      {:ok, {point, _}} = parse(format(latitude: "5206343S"))
      assert point.latitude == -52.105716666666666
    end

    test "with E longitude" do
      {:ok, {point, _}} = parse(format(longitude: "00006198E"))
      assert point.longitude == 0.1033
    end

    test "with V validity" do
      {:ok, {point, _}} = parse(format(validity: "V"))
      assert point.validity == "V"
    end

    test "with negative pressure_altitude" do
      {:ok, {point, _}} = parse(format(pressure_altitude: "-0003"))
      assert point.pressure_altitude == -3
    end
  end
end
