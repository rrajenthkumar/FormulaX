defmodule FormulaX.ParametersTest do
  use ExUnit.Case

  alias FormulaX.Parameters

  test "race_distance" do
    actual = Parameters.race_distance()

    expected = 650.0

    assert actual === expected
  end

  test "lanes" do
    actual = Parameters.lanes()

    expected = [
      %{lane_number: 1, x_start: 0.0, x_end: 6.0},
      %{lane_number: 2, x_start: 6.0, x_end: 12.0},
      %{lane_number: 3, x_start: 12.0, x_end: 18.0}
    ]

    assert actual === expected
  end

  test "driving_area_limits" do
    actual = Parameters.driving_area_limits()

    expected = %{x_start: 0.0, x_end: 18.0}

    assert actual === expected
  end

  test "car_length" do
    actual = Parameters.car_length()

    expected = 7.0

    assert actual === expected
  end

  test "car_initial_positions" do
    actual = Parameters.car_initial_positions()

    expected = [
      {1.25, 1.0},
      {7.25, 1.0},
      {13.25, 1.0},
      {1.25, 9.0},
      {7.25, 9.0},
      {13.25, 9.0}
    ]

    assert actual === expected
  end

  test "number_of_cars" do
    actual = Parameters.number_of_cars()

    expected = 6

    assert actual === expected
  end

  describe "car_drive_step" do
    test "rest" do
      actual = Parameters.car_drive_step(:rest)

      expected = 0.0

      assert actual === expected
    end

    test "low" do
      actual = Parameters.car_drive_step(:low)

      expected = 4.0

      assert actual === expected
    end

    test "moderate" do
      actual = Parameters.car_drive_step(:moderate)

      expected = 5.0

      assert actual === expected
    end

    test "high" do
      actual = Parameters.car_drive_step(:high)

      expected = 6.0

      assert actual === expected
    end

    test "speed_boost" do
      actual = Parameters.car_drive_step(:speed_boost)

      expected = 7.0

      assert actual === expected
    end
  end

  test "car_steering_step" do
    actual = Parameters.car_steering_step()

    expected = 6.0

    assert actual === expected
  end

  test "obstacle_and_speed_boost_length" do
    actual = Parameters.obstacle_and_speed_boost_length()

    expected = 7.0

    assert actual === expected
  end

  test "obstacles_and_speed_boosts_prohibited_distance" do
    actual = Parameters.obstacles_and_speed_boosts_prohibited_distance()

    expected = 60.0

    assert actual === expected
  end

  test "obstacles_and_speed_boosts_x_positions" do
    actual = Parameters.obstacles_and_speed_boosts_x_positions()

    expected = [0.0, 6.0, 12.0]

    assert actual === expected
  end

  test "obstacle_y_position_steps" do
    actual = Parameters.obstacle_y_position_steps()

    expected = [30.0, 60.0, 90.0]

    assert actual === expected
  end

  test "max_obstacle_y_position_step" do
    actual = Parameters.max_obstacle_y_position_step()

    expected = 90.0

    assert actual === expected
  end

  test "speed_boost_y_position_step" do
    actual = Parameters.speed_boost_y_position_step()

    expected = 300.0

    assert actual === expected
  end

  test "console_screen_height" do
    actual = Parameters.console_screen_height()

    expected = 35.0

    assert actual === expected
  end

  test "background_image_height" do
    actual = Parameters.background_image_height()

    expected = 8.5

    assert actual === expected
  end
end
