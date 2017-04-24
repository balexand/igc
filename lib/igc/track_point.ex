defmodule Igc.TrackPoint do
  @moduledoc """
  A GPS track point, or in IGC terminology a
  [B-Record](http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/igc_format_2008.html#link_4.1).
  """

  @enforce_keys [:latitude, :longitude, :validity, :pressure_altitude, :gps_altitude]
  defstruct @enforce_keys

  @format ~r/^B\d{6}(?<lat_deg>\d{2})(?<lat_kminute>\d{5})(?<lat_dir>N|S)(?<lng_deg>\d{3})(?<lng_kminute>\d{5})(?<lng_dir>W|E)(?<validity>A|V)(?<pressure_altitude>(\d|-)\d{4})(?<gps_altitude>\d{5})/

  @doc ~S"""
  Parses an instance from an IGC B-Record string. See
  [this article](http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/)
  for a description of the format as well as the example below.

  ## Examples

      iex> Igc.TrackPoint.parse("B1101355206343N00006198WA0058700558")
      {:ok, %Igc.TrackPoint{
        latitude: 52.105716666666666,
        longitude: -0.1033,
        validity: "A",
        pressure_altitude: 587,
        gps_altitude: 558
      }}

      iex> Igc.TrackPoint.parse("B1101355206343X00006198WA0058700558")
      {:error, "invalid format: \"B1101355206343X00006198WA0058700558\""}
  """
  def parse(data) do
    case Regex.named_captures(@format, data) do
      nil -> {:error, "invalid format: #{inspect data}"}
      %{
        "lat_deg" => lat_deg, "lat_kminute" => lat_kminute, "lat_dir" => lat_dir,
        "lng_deg" => lng_deg, "lng_kminute" => lng_kminute, "lng_dir" => lng_dir,
        "validity" => validity,
        "pressure_altitude" => pressure_altitude,
        "gps_altitude" => gps_altitude
      } ->
        {:ok, %__MODULE__{
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
