defmodule Igc do
  alias Igc.{Track, TrackPoint}

  @moduledoc """
  Documentation for Igc.
  """

  @doc ~S"""
  Parses an IGC file.

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
  """
  def parse(str) when is_binary(str) do
    {:ok, io} = StringIO.open(str)
    try do: parse(io), after: {:ok, _} = StringIO.close(io)
  end

  def parse(io) when is_pid(io) do
    with {:ok, track} <- parse(%Track{}, io),
         do: {:ok, update_in(track.points, &Enum.reverse/1)}
  end

  defp parse(track, io) do
    case IO.read(io, :line) do
      :eof -> {:ok, track}
      # TODO handle FS errors
      line when is_binary(line) ->
        with {:ok, track} <- handle_line(track, String.trim(line)),
             do: parse(track, io)
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
    with {:ok, point} <- TrackPoint.parse("B" <> b_record),
         do: {:ok, update_in(track.points, &([point | &1]))}
  end

  defp handle_line(track, _line), do: {:ok, track} # TODO ensure test coverage
end
