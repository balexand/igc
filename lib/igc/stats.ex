defmodule Igc.Stats do
  defstruct max_climb: 0

  @window_size_sec 30

  alias Igc.{Track, TrackPoint}

  def calculate(%Track{points: points}) do
    # points -> averaged points -> diffs -> max/min

    {average_points, _} =
      points
      |> Enum.map(&to_average_point/1)
      |> Enum.flat_map_reduce([], &rolling_average/2)

    [head|tail] = average_points

    {rates, _} = Enum.map_reduce(tail, head, fn(point, prev) ->
      a = (point.pressure_altitude - prev.pressure_altitude) / (point.timestamp - prev.timestamp)

      rate = %{point |
        pressure_altitude: a
      }

      {rate, point}
    end)

    %__MODULE__{
      max_climb: Enum.max(Enum.map(rates, & &1.pressure_altitude))
    }
  end

  defmodule AveragePoint do
    @moduledoc false
    defstruct [:timestamp, :pressure_altitude]
  end

  defp rolling_average(point, []) do
    {[], [point]}
  end

  defp rolling_average(%AveragePoint{} = point, previous) when is_list(previous) do
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
      pressure_altitude: point.pressure_altitude,
    }
  end
end
