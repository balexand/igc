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
    parse(io)
  end

  def parse(io) when is_pid(io) do
    case parse(%Track{}, io) do
      {:ok, track} -> {:ok, update_in(track.points, &Enum.reverse/1)}
      result -> result
    end
  end

  defp parse(track, io) do
    case IO.read(io, :line) do
      :eof -> {:ok, track}
      line when is_binary(line) ->
        case handle_line(track, String.trim(line)) do
          {:ok, track} -> parse(track, io)
          {:error, detail} -> {:error, detail}
        end
    end
  end

  defp handle_line(track, <<"HFDTE", ddmmyy::binary>>) do
    case Timex.parse(ddmmyy, "{0D}{0M}{YY}") do
      {:ok, datetime} -> {:ok, put_in(track.date, Timex.to_date(datetime))}
      {:error, _} -> {:error, "invalid date: #{inspect("HFDTE"<>ddmmyy)}"}
    end
  end

  defp handle_line(track, <<"B", b_record::binary>>) do
    case TrackPoint.parse("B" <> b_record) do
      {:ok, point} -> {:ok, update_in(track.points, &([point | &1]))}
      {:error, detail} -> {:error, detail}
    end
  end

  defp handle_line(track, _line), do: {:ok, track} # TODO ensure test coverage
end
