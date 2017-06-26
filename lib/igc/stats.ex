defmodule Igc.Stats do
  defstruct distance: nil, duration: nil, max_altitude: nil, min_altitude: nil

  alias Igc.{Track, TrackPoint}

  def calculate(%Track{landing: landing, points: points, take_off: take_off}) do
    # FIXME some devices don't include GPS alt: https://github.com/balexand/igc/issues/18
    altitudes = Enum.map(points, & &1.gps_altitude)

    %__MODULE__{
      distance: total_distance(points),
      duration: NaiveDateTime.diff(landing.datetime, take_off.datetime, :second),
      max_altitude: Enum.max(altitudes),
      min_altitude: Enum.min(altitudes),
    }
  end

  defp distance(%TrackPoint{} = p1, %TrackPoint{} = p2) do
    Distance.GreatCircle.distance(
      {p1.longitude, p1.latitude},
      {p2.longitude, p2.latitude}
    )
  end

  defp total_distance([head | tail]) do
    {_, total} = Enum.reduce(tail, {head, 0}, fn(point, {prev, total}) ->
      {point, total + distance(point, prev)}
    end)

    round(total)
  end
end
