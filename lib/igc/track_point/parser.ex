defmodule Igc.TrackPoint.Parser do
  @moduledoc false

  alias Igc.TrackPoint

  # Parses an IGC B-Record. For details, see
  # http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/
  def parse(data) do
    with << "B",
            hour::bytes-size(2),
            minute::bytes-size(2),
            second::bytes-size(2),
            lat_deg::bytes-size(2),
            lat_kminute::bytes-size(5),
            lat_dir::bytes-size(1),
            lng_deg::bytes-size(3),
            lng_kminute::bytes-size(5),
            lng_dir::bytes-size(1),
            validity::bytes-size(1),
            pressure_altitude::bytes-size(5),
            gps_altitude::bytes-size(5),
            _trailing::binary >> <- data,
         {:ok, time} <- parse_time(hour, minute, second),
         {:ok, lat} <- parse_coord(lat_deg, lat_kminute, lat_dir, {"S", "N"}),
         {:ok, lng} <- parse_coord(lng_deg, lng_kminute, lng_dir, {"W", "E"}),
         {:ok, pressure_altitude} <- parse_int(pressure_altitude),
         {:ok, gps_altitude} <- parse_int(gps_altitude)
    do
      point = %TrackPoint{
        latitude: lat,
        longitude: lng,
        validity: validity,
        pressure_altitude: pressure_altitude,
        gps_altitude: gps_altitude
      }

      {:ok, {point, time}}
    else
      _ -> {:error, "invalid track point: #{inspect data}"}
    end
  end

  defp parse_time(hour, minute, second) do
    with {:ok, hour} <- parse_int(hour),
         {:ok, minute} <- parse_int(minute),
         {:ok, second} <- parse_int(second),
    do: Time.new(hour, minute, second)
  end

  defp parse_coord(deg, kminutes, dir, dirs) do
    with {:ok, deg} <- parse_int(deg),
         {:ok, kminutes} <- parse_int(kminutes),
         {:ok, sign} <- coord_sign(dir, dirs)
    do
      {:ok, (deg + kminutes * 0.001 / 60) * sign}
    end
  end

  defp coord_sign(neg, {neg, _pos}), do: {:ok, -1}
  defp coord_sign(pos, {_neg, pos}), do: {:ok, 1}
  defp coord_sign(_, _), do: :error

  defp parse_int(str) do
    try do
      {:ok, String.to_integer(str)}
    rescue
      ArgumentError -> :error
    end
  end
end
