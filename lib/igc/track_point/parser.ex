defmodule Igc.TrackPoint.Parser do
  @moduledoc false

  alias Igc.TrackPoint

  @format ~r/^B\d{6}(?<lat_deg>\d{2})(?<lat_kminute>\d{5})(?<lat_dir>N|S)(?<lng_deg>\d{3})(?<lng_kminute>\d{5})(?<lng_dir>W|E)(?<validity>A|V)(?<pressure_altitude>(\d|-)\d{4})(?<gps_altitude>\d{5})/

  # Parses an IGC B-Record. For details, see
  # http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/
  def parse(data) do
    case Regex.named_captures(@format, data) do
      nil -> {:error, "invalid track point: #{inspect data}"}
      %{
        "lat_deg" => lat_deg, "lat_kminute" => lat_kminute, "lat_dir" => lat_dir,
        "lng_deg" => lng_deg, "lng_kminute" => lng_kminute, "lng_dir" => lng_dir,
        "validity" => validity,
        "pressure_altitude" => pressure_altitude,
        "gps_altitude" => gps_altitude
      } ->
        {:ok, %TrackPoint{
          latitude: parse_coord!(lat_deg, lat_kminute, lat_dir, {"S", "N"}),
          longitude: parse_coord!(lng_deg, lng_kminute, lng_dir, {"W", "E"}),
          validity: validity,
          pressure_altitude: parse_altitude(pressure_altitude),
          gps_altitude: parse_altitude(gps_altitude)
        }}
    end
  end

  defp parse_altitude(altitude) do
    {result, ""} = Integer.parse(altitude)
    result
  end

  defp parse_coord!(deg, kminutes, direction, {negative, positive}) do
    {deg, ""} = Integer.parse(deg)
    {kminutes, ""} = Integer.parse(kminutes)

    sign = case direction do
      ^negative -> -1
      ^positive ->  1
    end

    (deg + kminutes * 0.001 / 60) * sign
  end
end
