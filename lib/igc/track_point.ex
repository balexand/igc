defmodule Igc.TrackPoint do
  @moduledoc """
  A GPS track point, or in IGC terminology a
  [B-Record](http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/igc_format_2008.html#link_4.1).
  """

  @enforce_keys [:latitude, :longitude]
  defstruct @enforce_keys

  @format ~r/^B\d{6}(?<lat_deg>\d{2})(?<lat_kminute>\d{5})(?<lat_dir>N|S)(?<lng_deg>\d{3})(?<lng_kminute>\d{5})(?<lng_dir>W|E)/

  @doc ~S"""
  Parses an instance from an IGC B-Record string.

  ## Examples

      iex> Igc.TrackPoint.parse("B1101355206343N00006198WA0058700558")
      {:ok, %Igc.TrackPoint{
        latitude: 52.105716666666666,
        longitude: -0.1033
      }}

      iex> Igc.TrackPoint.parse("B1101355206343X00006198WA0058700558")
      {:error, "invalid format: \"B1101355206343X00006198WA0058700558\""}
  """
  def parse(data) do
    case Regex.named_captures(@format, data) do
      nil -> {:error, "invalid format: #{inspect data}"}
      %{
        "lat_deg" => lat_deg, "lat_kminute" => lat_kminute, "lat_dir" => lat_dir,
        "lng_deg" => lng_deg, "lng_kminute" => lng_kminute, "lng_dir" => lng_dir
      } ->
        {:ok, %__MODULE__{
          latitude: coord_to_dec!(lat_deg, lat_kminute, lat_dir, {"S", "N"}),
          longitude: coord_to_dec!(lng_deg, lng_kminute, lng_dir, {"W", "E"}),
        }}
    end
  end

  @doc """
  Same as parse/1, but raises on error.
  """
  def parse!(data) do
    {:ok, result} = parse(data)
    result
  end

  defp coord_to_dec!(deg, kminutes, direction, {negative, positive}) do
    {deg, ""} = Integer.parse(deg)
    {kminutes, ""} = Integer.parse(kminutes)

    sign = case direction do
      ^negative -> -1
      ^positive ->  1
    end

    (deg + kminutes * 0.001 / 60) * sign
  end
end
