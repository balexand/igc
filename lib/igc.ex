defmodule Igc do
  alias Igc.{Track, TrackPoint}

  @moduledoc """
  Documentation for Igc.
  """

  @doc ~S"""
  Parses an IGC file.

  It returns:
  * `{:ok, track}` upon success
  * `{:error, reason}` when the IGC file is invalid, where `reason` is a human
    readable string explaining why the IGC is invalid

  ## Examples

      iex> Igc.parse("HFDTE280709\nB1101355206343N00006198WA0058700558")
      {:ok, %Igc.Track{
        date: ~D[2009-07-28],
        points: [%Igc.TrackPoint{
          datetime: ~N[2009-07-28 11:01:35],
          gps_altitude: 558,
          latitude: 52.105716666666666,
          longitude: -0.1033,
          pressure_altitude: 587,
          validity: "A"
        }]
      }}

      iex> Igc.parse("HFDTE320709")
      {:error, "invalid date: \"HFDTE320709\""}
  """
  def parse(str) when is_binary(str) do
    String.splitter(str, ["\r\n", "\n"], trim: true)
    |> Enum.reduce_while(%Track{}, fn line, track ->
      case handle_line(track, String.trim(line)) do
        {:ok, track} -> {:cont, track}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> post_process
  end

  defp handle_line(track, <<"HFDTE", ddmmyy::binary>>) do
    with {:ok, datetime} <- Timex.parse(ddmmyy, "{0D}{0M}{YY}") do
      {:ok, put_in(track.date, Timex.to_date(datetime))}
    else
      _ -> {:error, "invalid date: #{inspect("HFDTE"<>ddmmyy)}"}
    end
  end

  defp handle_line(track, <<"B", b_record::binary>>) do
    with {:ok, point} <- TrackPoint.Parser.parse("B" <> b_record),
         do: {:ok, update_in(track.points, &([point | &1]))}
  end

  defp handle_line(track, _line), do: {:ok, track}

  defp post_process(track = %Track{}) do
    # TODO handle file without date
    track = update_in(track.points, fn pairs ->
      pairs
      |> Enum.reverse
      |> Enum.map(fn {point, time} ->
        {:ok, datetime} = NaiveDateTime.new(track.date, time)
        put_in point.datetime, datetime
      end)
    end)

    {:ok, track}
  end

  defp post_process(error), do: error
end
