defmodule Igc.Stats.RollingAverage do
  @moduledoc false

  @window_size_sec 30

  def average(items) do
    {avg_items, _} = Enum.flat_map_reduce(items, [], &rolling_average_reducer/2)
    avg_items
  end

  defp rolling_average_reducer(point, []) do
    {[], [point]}
  end

  defp rolling_average_reducer(point, previous) when is_list(previous) do
    new_window = average_window(point, previous)
    count = Enum.count(new_window)

    keys = Map.delete(point, :__struct__) |> Map.keys

    average_point = Enum.reduce(keys, point, fn(key, i) ->
      sum = new_window |> Enum.map(&Map.get(&1, key)) |> Enum.sum
      Map.put(i, key, sum / count)
    end)

    # FIXME drop pre-average points

    {[average_point], new_window}
  end

  defp average_window(current, previous) when is_list(previous) do
    filtered = Enum.filter(previous, fn(i) ->
      current.timestamp - i.timestamp <= @window_size_sec
    end)

    [current | filtered]
  end
end
