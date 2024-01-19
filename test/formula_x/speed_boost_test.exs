defmodule FormulaX.SpeedBoostTest do
  use ExUnit.Case

  alias FormulaX.Fixtures
  alias FormulaX.Race.SpeedBoost

  test "initialize_initialize_speed_boost" do
    speed_boost = SpeedBoost.initialize_speed_boost(_distance_covered_with_speed_boosts = 360.0)

    assert speed_boost.__struct__ === SpeedBoost
    assert speed_boost.x_position in [0.0, 6.0, 12.0]
    assert speed_boost.distance === 660.0
  end

  test "get_y_position" do
    speed_boost = Fixtures.speed_boost(%{distance: 960.0})

    player_car = Fixtures.car(%{y_position: 1.0, distance_travelled: 945.0})

    race = Fixtures.race(%{player_car: player_car})

    actual = SpeedBoost.get_y_position(speed_boost, race)

    expected = 14.0

    assert actual === expected
  end

  test "get_lane" do
    actual =
      Fixtures.speed_boost()
      |> SpeedBoost.get_lane()

    expected = 3

    assert actual === expected
  end

  test "enable_if_fetched" do
    speed_boost = Fixtures.speed_boost(%{x_position: 0.0, distance: 360.0})

    pre_player_car = Fixtures.car(%{distance_travelled: 340.0})

    race = Fixtures.race(%{player_car: pre_player_car, speed_boosts: [speed_boost]})

    actual = SpeedBoost.enable_if_fetched(race)

    post_player_car = Fixtures.car(%{distance_travelled: 340.0, speed: :speed_boost})

    expected = Fixtures.race(%{player_car: post_player_car, speed_boosts: [speed_boost]})

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
