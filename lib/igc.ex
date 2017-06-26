defmodule Igc do
  alias Igc.{Track, TrackPoint}

  @moduledoc """
  Documentation for Igc.
  """

  @doc ~S"""
  Parses an IGC string.

  It returns:
  * `{:ok, track}` upon success
  * `{:error, reason}` when the IGC file is invalid, where `reason` is a human
    readable string explaining why the IGC is invalid
  """
  def parse(str) when is_binary(str) do
    String.splitter(str, ["\r\n", "\n"], trim: true)
    |> Enum.reduce_while(%Track{}, fn line, track ->
      case handle_line(track, String.trim(line)) do
        {:ok, track} -> {:cont, track}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      %Track{} = track -> post_process(track)
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_line(track, <<"HFDTE", ddmmyy::binary>>) do
    with {:ok, date} <- parse_date(ddmmyy) do
      {:ok, put_in(track.date, date)}
    else
      _ -> {:error, "invalid date: #{inspect("HFDTE"<>ddmmyy)}"}
    end
  end

  defp handle_line(track, <<"B", b_record::binary>>) do
    with {:ok, point} <- TrackPoint.Parser.parse("B" <> b_record),
         do: {:ok, update_in(track.points, &([point | &1]))}
  end

  defp handle_line(track, _line), do: {:ok, track}

  defp post_process(%Track{date: nil}), do: {:error, "file must include date"}

  defp post_process(track = %Track{}) do
    {:ok, start} = NaiveDateTime.new(track.date, ~T[00:00:00])

    track = update_in(track.points, fn pairs ->
      pairs
      |> Enum.reverse
      |> Enum.map_reduce(start, fn({point, time}, last_datetime) ->
        {:ok, datetime} = NaiveDateTime.new(NaiveDateTime.to_date(last_datetime), time)

        datetime = case NaiveDateTime.compare(datetime, last_datetime) do
          :lt -> increment_date(datetime)
          _ -> datetime
        end

        {put_in(point.datetime, datetime), datetime}
      end)
      |> elem(0)
    end)

    {:ok, track}
  end

  defp parse_date(<<day::bytes-size(2), month::bytes-size(2), year::bytes-size(2)>>) do
    with {day, ""} <- Integer.parse(day),
         {month, ""} <- Integer.parse(month),
         {year, ""} <- Integer.parse(year),
         {:ok, date} <- Date.new(year + 2000, month, day),
    do: {:ok, date},
    else: (_ -> :error)
  end

  defp parse_date(_), do: :error

  defp increment_date(datetime = %NaiveDateTime{}) do
    days = datetime
    |> NaiveDateTime.to_date
    |> Date.to_erl
    |> :calendar.date_to_gregorian_days

    {:ok, incremented} = days + 1
    |> :calendar.gregorian_days_to_date
    |> Date.from_erl!
    |> NaiveDateTime.new(NaiveDateTime.to_time(datetime))

    incremented
  end
end
