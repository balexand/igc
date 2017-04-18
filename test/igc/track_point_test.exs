defmodule Igc.TrackPointTest do
  alias Igc.TrackPoint

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

  describe "parse!" do
    test "with S latitude" do
      assert TrackPoint.parse!(format(latitude: "5206343S")).latitude == -52.105716666666666
    end

    test "with E longitude" do
      assert TrackPoint.parse!(format(longitude: "00006198E")).longitude == 0.1033
    end

    test "with V validity" do
      assert TrackPoint.parse!(format(validity: "V")).validity == "V"
    end

    test "with negative pressure_altitude" do
      assert TrackPoint.parse!(format(pressure_altitude: "-0003")).pressure_altitude == -3
    end
  end
end
