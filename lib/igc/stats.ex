defmodule Igc.Stats do
  defstruct max_climb: 0

  alias Igc.{Track, TrackPoint}

  defmodule AveragePoint do
    @moduledoc false
    defstruct [:timestamp, :pressure_altitude]
  end

  def calculate(%Track{points: points}) do
    # points -> averaged points -> diffs -> max/min

    points
    |> Enum.map(&to_average_point/1)
    |> Igc.Stats.RollingAverage.average()
    |> to_rates
    |> Enum.reduce(%__MODULE__{}, fn(rate, stats) ->
      %{stats |
        max_climb: max(stats.max_climb, rate.pressure_altitude)
      }
    end)
  end

  defp to_rates([head | tail]) do
    {rates, _} = Enum.map_reduce(tail, head, fn(point, prev) ->
      # FIXME cleanup
      a = (point.pressure_altitude - prev.pressure_altitude) / (point.timestamp - prev.timestamp)

      rate = %{point |
        pressure_altitude: a
      }

      {rate, point}
    end)

    rates
  end

  defp to_average_point(%TrackPoint{} = point) do
    %AveragePoint{
      timestamp: point.datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix,
      pressure_altitude: point.pressure_altitude, # FIXME cleanup
    }
  end
end
