defmodule Igc.Stats do
  defstruct max_climb: 0

  @window_size_sec 30

  alias Igc.{Track, TrackPoint}

  defmodule AveragePoint do
    @moduledoc false
    defstruct [:timestamp, :pressure_altitude]
  end

  def calculate(%Track{points: points}) do
    # points -> averaged points -> diffs -> max/min

    points
    |> Enum.map(&to_average_point/1)
    |> to_rolling_average
    |> to_rates
    |> Enum.reduce(%__MODULE__{}, fn(rate, stats) ->
      %{stats |
        max_climb: max(stats.max_climb, rate.pressure_altitude)
      }
    end)
  end

  defp to_rolling_average(points) do
    {avg_points, _} = Enum.flat_map_reduce(points, [], &rolling_average_reducer/2)
    avg_points
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

  defp rolling_average_reducer(point, []) do
    {[], [point]}
  end

  defp rolling_average_reducer(%AveragePoint{} = point, previous) when is_list(previous) do
    new_window = average_window(point, previous)

    # FIXME cleanup
    # FIXME drop pre-average points
    average_point = %{point |
      timestamp: (Enum.map(new_window, & &1.timestamp) |> Enum.sum) / Enum.count(new_window),
      pressure_altitude: (Enum.map(new_window, & &1.pressure_altitude) |> Enum.sum) / Enum.count(new_window),
    }

    {[average_point], new_window}
  end

  defp average_window(%AveragePoint{} = current, previous) when is_list(previous) do
    filtered = Enum.filter(previous, fn(i) ->
      current.timestamp - i.timestamp <= @window_size_sec
    end)

    [current | filtered]
  end

  defp to_average_point(%TrackPoint{} = point) do
    %AveragePoint{
      timestamp: point.datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix,
      pressure_altitude: point.pressure_altitude, # FIXME cleanup
    }
  end
end
