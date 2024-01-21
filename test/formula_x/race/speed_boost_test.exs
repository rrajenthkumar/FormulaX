defmodule FormulaX.Race.SpeedBoostTest do
  use ExUnit.Case

  alias FormulaX.Fixtures
  alias FormulaX.Race.SpeedBoost

  test "initialize_initialize_speed_boost" do
    speed_boost = SpeedBoost.initialize_speed_boost(_distance_covered_with_speed_boosts = 360.0)

    assert speed_boost.__struct__ === SpeedBoost
    assert speed_boost.x_position in [0.0, 6.0, 12.0]
    assert speed_boost.distance === 660.0
  end

  test "get_lane" do
    actual =
      Fixtures.speed_boost()
      |> SpeedBoost.get_lane()

    expected = 3

    assert actual === expected
  end

  test "new" do
    actual =
      %{
        x_position: 12.0,
        distance: 660.0
      }
      |> SpeedBoost.new()

    expected = %SpeedBoost{
      x_position: 12.0,
      distance: 660.0
    }

    assert actual === expected
  end
end
