defmodule Igc.TrackPoint.Parser do
  @moduledoc false

  alias Igc.TrackPoint

  # Parses an IGC B-Record. For details, see
  # http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/
  def parse(data) do
    data = String.slice(data, 0..34)

    with <<"B",
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
            gps_altitude::bytes-size(5)>> <- data,
         {:ok, time} <- parse_time(hour, minute, second),
         {:ok, lat} <- parse_coord(lat_deg, lat_kminute, lat_dir, {"S", "N"}),
         {:ok, lng} <- parse_coord(lng_deg, lng_kminute, lng_dir, {"W", "E"}),
         {pressure_altitude, ""} <- Integer.parse(pressure_altitude),
         {gps_altitude, ""} <- Integer.parse(gps_altitude)
    do
      {:ok, {
        %TrackPoint{
          latitude: lat,
          longitude: lng,
          validity: validity,
          pressure_altitude: pressure_altitude,
          gps_altitude: gps_altitude
        },
        time
      }}
    else
      _ -> {:error, "invalid track point: #{inspect data}"}
    end
  end

  defp parse_time(hour, minute, second) do
    with {hour, ""} <- Integer.parse(hour),
         {minute, ""} <- Integer.parse(minute),
         {second, ""} <- Integer.parse(second),
    do: Time.new(hour, minute, second)
  end

  defp parse_coord(deg, kminutes, dir, dirs) do
    with {deg, ""} <- Integer.parse(deg),
         {kminutes, ""} <- Integer.parse(kminutes),
         {:ok, sign} <- coord_sign(dir, dirs)
    do
      {:ok, (deg + kminutes * 0.001 / 60) * sign}
    end
  end

  defp coord_sign(neg, {neg, _pos}), do: {:ok, -1}
  defp coord_sign(pos, {_neg, pos}), do: {:ok, 1}
  defp coord_sign(_, _), do: :error
end
