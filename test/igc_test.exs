defmodule IgcTest do
  use ExUnit.Case, async: true
  doctest Igc

  describe "parse/1" do
    test "with invalid HFDTE" do
      assert Igc.parse("HFDTE320709\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: HFDTE320709"}

      assert Igc.parse("HFDTEXX0709\nB1101355206343N00006198WA0058700558") ==
        {:error, "invalid date: HFDTEXX0709"}
    end
  end
end
