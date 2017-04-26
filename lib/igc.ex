defmodule Igc do
  alias Igc.{Track, TrackPoint}

  @moduledoc """
  Documentation for Igc.
  """

  @doc ~S"""
  Parses an IGC file.

  It returns:
  * `{:ok, track}` upon success
  * `{:error, :invalid_igc, reason}` when the IGC file is invalid, where
    `reason` is a human readable string explaining why the IGC is invalid
  * `{:error, :io, reason}` when an error is returned by `IO.read/2`

  ## Examples

      iex> Igc.parse("HFDTE280709\nB1101355206343N00006198WA0058700558")
      {:ok, %Igc.Track{
        date: ~D[2009-07-28],
        points: [%Igc.TrackPoint{
          gps_altitude: 558,
          latitude: 52.105716666666666,
          longitude: -0.1033,
          pressure_altitude: 587,
          validity: "A"
        }]
      }}

      iex> Igc.parse("HFDTE320709")
      {:error, :invalid_igc, "invalid date: \"HFDTE320709\""}
  """
  def parse(str) when is_binary(str) do
    {:ok, io} = StringIO.open(str)
    try do: parse(io), after: {:ok, _} = StringIO.close(io)
  end

  def parse(io) when is_pid(io) do
    with {:ok, track} <- do_parse(%Track{}, io),
         do: {:ok, update_in(track.points, &Enum.reverse/1)}
  end

  defp do_parse(track, io) do
    case IO.read(io, :line) do
      :eof -> {:ok, track}
      {:error, reason} -> {:error, :io, reason}
      line when is_binary(line) ->
        case handle_line(track, String.trim(line)) do
          {:ok, track} -> do_parse(track, io)
          {:error, reason} -> {:error, :invalid_igc, reason}
        end
    end
  end

  defp handle_line(track, <<"HFDTE", ddmmyy::binary>>) do
    with {:ok, datetime} <- Timex.parse(ddmmyy, "{0D}{0M}{YY}") do
      {:ok, put_in(track.date, Timex.to_date(datetime))}
    else
      _ -> {:error, "invalid date: #{inspect("HFDTE"<>ddmmyy)}"}
    end
  end

  defp handle_line(track, <<"B", b_record::binary>>) do
    with {:ok, {point, _time}} <- TrackPoint.Parser.parse("B" <> b_record),
         do: {:ok, update_in(track.points, &([point | &1]))}
  end

  defp handle_line(track, _line), do: {:ok, track}
end
