defmodule Igc.Geo do
  @doc ~S"""
  Converts from IGC waypoint format to decimal latitude and longitude.

  ## Examples

      iex> Igc.Geo.to_dec!("4722676N", "01343272E")
      {47.37793333333333, 13.7212}

      iex> Igc.Geo.to_dec!("5206343N", "00006198W")
      {52.105716666666666, -0.1033}

  """
  def to_dec!(lat, lng) do
    {
      Regex.run(~r/^(\d{2})(\d{5})([A-Z])/, lat) |> field_to_dec!("S", "N"),
      Regex.run(~r/^(\d{3})(\d{5})([A-Z])/, lng) |> field_to_dec!("W", "E")
    }
  end

  defp field_to_dec!([_, deg, kminutes, direction], negative, positive) do
    {deg, ""} = Integer.parse(deg)
    {kminutes, ""} = Integer.parse(kminutes)

    sign = case direction do
      ^negative -> -1
      ^positive -> 1
    end

    (deg + kminutes * 0.001 / 60) * sign
  end
end
