defmodule Igc.Stats do
  defstruct [:distance, :duration, :max_altitude, :min_altitude]

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

  defp distance(%TrackPoint{location: loc1}, %TrackPoint{location: loc2}) do
    Distance.GreatCircle.distance(loc1, loc2)
  end

  defp total_distance([head | tail]) do
    {total, _} = Enum.reduce(tail, {0, head}, fn(point, {total, prev}) ->
      {total + distance(point, prev), point}
    end)

    round(total)
  end
end
