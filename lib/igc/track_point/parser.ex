defmodule Igc.TrackPoint.Parser do
  @moduledoc false

  alias Igc.TrackPoint

  @format ~r/^B(?<hour>\d{2})(?<minute>\d{2})(?<second>\d{2})(?<lat_deg>\d{2})(?<lat_kminute>\d{5})(?<lat_dir>N|S)(?<lng_deg>\d{3})(?<lng_kminute>\d{5})(?<lng_dir>W|E)(?<validity>A|V)(?<pressure_altitude>(\d|-)\d{4})(?<gps_altitude>\d{5})/

  # Parses an IGC B-Record. For details, see
  # http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/
  def parse(data) do
    case Regex.named_captures(@format, data) do
      nil -> {:error, "invalid track point: #{inspect data}"}
      %{
        "hour" => hour, "minute" => minute, "second" => second,
        "lat_deg" => lat_deg, "lat_kminute" => lat_kminute, "lat_dir" => lat_dir,
        "lng_deg" => lng_deg, "lng_kminute" => lng_kminute, "lng_dir" => lng_dir,
        "validity" => validity,
        "pressure_altitude" => pressure_altitude,
        "gps_altitude" => gps_altitude
      } ->
        {:ok, {
          %TrackPoint{
            latitude: parse_coord!(lat_deg, lat_kminute, lat_dir, {"S", "N"}),
            longitude: parse_coord!(lng_deg, lng_kminute, lng_dir, {"W", "E"}),
            validity: validity,
            pressure_altitude: String.to_integer(pressure_altitude),
            gps_altitude: String.to_integer(gps_altitude)
          },
          parse_time(hour, minute, second)
        }}
    end
  end

  defp parse_time(hour, minute, second) do
    [hour, minute, second] = [hour, minute, second]
    |> Enum.map(&String.to_integer/1)

    {:ok, time} = Time.new(hour, minute, second)
    time
  end

  defp parse_coord!(deg, kminutes, direction, {negative, positive}) do
    deg = String.to_integer(deg)
    kminutes = String.to_integer(kminutes)

    sign = case direction do
      ^negative -> -1
      ^positive ->  1
    end

    (deg + kminutes * 0.001 / 60) * sign
  end
end
