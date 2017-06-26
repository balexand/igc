defmodule Igc.Stats do
  defstruct max_climb: 0

  alias Igc.{Track, TrackPoint}

  defmodule AveragePoint do
    @moduledoc false
    defstruct [:timestamp, :pressure_altitude]
  end

  defmodule RatePoint do
    @moduledoc false
    defstruct [:climb_rate]
  end

  def calculate(%Track{points: points}) do
    points
    |> Enum.map(&to_average_point/1)
    |> Igc.Stats.RollingAverage.average()
    |> to_rates
    |> Enum.reduce(%__MODULE__{}, fn(%RatePoint{} = rate, %__MODULE__{} = stats) ->
      %{stats |
        max_climb: max(stats.max_climb, rate.climb_rate)
      }
    end)
  end

  defp to_rates([head | tail]) do
    {rates, _} = Enum.map_reduce(tail, head, &to_rate_reducer/2)
    rates
  end

  defp to_rate_reducer(%AveragePoint{} = point, %AveragePoint{} = prev) do
    delta_t = point.timestamp - prev.timestamp

    rate = %RatePoint{
      climb_rate: (point.pressure_altitude - prev.pressure_altitude) / delta_t
    }

    {rate, point}
  end

  defp to_average_point(%TrackPoint{} = point) do
    %AveragePoint{}
    |> Map.drop([:__struct__, :timestamp])
    |> Map.keys
    |> Enum.reduce(%AveragePoint{}, fn(k, i) -> %{i | k => Map.get(point, k)} end)
    |> Map.put(:timestamp, point.datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix)
  end
end
