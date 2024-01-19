defmodule FormulaX.ObstacleTest do
  use ExUnit.Case

  alias FormulaX.Fixtures
  alias FormulaX.Race.Obstacle

  test "initialize_obstacle" do
    obstacle = Obstacle.initialize_obstacle(_distance_covered_with_obstacles = 500.0)

    assert obstacle.__struct__ === Obstacle
    assert obstacle.x_position in [0.0, 6.0, 12.0]
    assert obstacle.distance in [530.0, 560.0, 590.0]
  end

  test "get_y_position" do
    obstacle = Fixtures.obstacle(%{distance: 160.0})

    player_car = Fixtures.car(%{y_position: 9.0, distance_travelled: 160.0})

    race = Fixtures.race(%{player_car: player_car})

    actual = Obstacle.get_y_position(obstacle, race)

    expected = -9.0

    assert actual === expected
  end

  test "get_lane" do
    actual =
      Fixtures.obstacle()
      |> Obstacle.get_lane()

    expected = 2

    assert actual === expected
  end

  test "new" do
    actual =
      %{
        x_position: 12.0,
        distance: 240.0
      }
      |> Obstacle.new()

    expected = %Obstacle{
      x_position: 12.0,
      distance: 240.0
    }

    assert actual === expected
  end
end
