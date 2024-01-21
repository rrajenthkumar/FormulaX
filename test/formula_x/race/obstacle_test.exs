defmodule FormulaX.Race.ObstacleTest do
  use ExUnit.Case

  alias FormulaX.Fixtures
  alias FormulaX.Race.Obstacle

  test "initialize_obstacle" do
    obstacle = Obstacle.initialize_obstacle(_distance_covered_with_obstacles = 500.0)

    assert obstacle.__struct__ === Obstacle
    assert obstacle.x_position in [0.0, 6.0, 12.0]
    assert obstacle.distance in [550.0, 600.0, 650.0]
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
