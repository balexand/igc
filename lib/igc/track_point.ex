defmodule Igc.TrackPoint do
  @moduledoc """
  A GPS track point, or in IGC terminology a
  [B-Record](http://carrier.csi.cam.ac.uk/forsterlewis/soaring/igc_file_format/igc_format_2008.html#link_4.1).
  """

  @enforce_keys [:latitude, :longitude, :validity, :pressure_altitude, :gps_altitude]
  defstruct [:datetime] ++ @enforce_keys
end
