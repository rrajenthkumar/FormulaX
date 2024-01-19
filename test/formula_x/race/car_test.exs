defmodule FormulaX.Race.CarTest do
  use ExUnit.Case

  alias FormulaX.Fixtures
  alias FormulaX.Race.Car

  test "initialize_player_car" do
    car = Car.initialize_player_car(_player_car_image_index = 0)

    assert car.__struct__ === Car
    assert car.id in 1..6
    assert car.controller === :player

    assert car.image in [
             "blue-red.png",
             "blue-with-spoiler.png",
             "blue.png",
             "red.png",
             "white-cabriolet.png",
             "white-with-spoiler.png",
             "white.png",
             "yellow-red.png",
             "yellow.png"
           ]

    assert car.x_position in [1.25, 7.25, 13.25]
    assert car.y_position in [1.0, 9.0]
    assert car.speed === :rest
    assert car.distance_travelled === 0.0
    assert car.completion_time === nil
  end

  test "initialize_autonomous_car" do
    car = Car.initialize_autonomous_car(_car_id = 3, "blue-with-spoiler.png")

    assert car.__struct__ === Car
    assert car.id === 3
    assert car.controller === :autonomous
    assert car.image === "blue-with-spoiler.png"
    assert car.x_position in [1.25, 7.25, 13.25]
    assert car.y_position in [1.0, 9.0]
    assert car.speed in [:low, :moderate, :high]
    assert car.distance_travelled === 0.0
    assert car.completion_time === nil
  end

  test "drive" do
    actual =
      Fixtures.car()
      |> Car.drive()

    expected = %Car{
      id: 1,
      controller: :player,
      image: "car.png",
      speed: :low,
      x_position: 1.25,
      y_position: 9.0,
      distance_travelled: 4.0
    }

    assert actual === expected
  end

  test "adapt_autonomous_car_position" do
    player_car = Fixtures.car(%{speed: :high, distance_travelled: 61.0})

    race = Fixtures.race(%{player_car: player_car})

    actual =
      Fixtures.car(%{id: 3, speed: :moderate, controller: :autonomous, distance_travelled: 64.0})
      |> Car.adapt_autonomous_car_position(race)

    expected = %Car{
      id: 3,
      controller: :autonomous,
      image: "car.png",
      speed: :moderate,
      x_position: 1.25,
      y_position: 4.0,
      distance_travelled: 64.0
    }

    assert actual === expected
  end

  describe "steer" do
    test "left" do
      actual =
        Fixtures.car()
        |> Car.steer(:left)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :low,
        x_position: -4.75,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "right" do
      actual =
        Fixtures.car()
        |> Car.steer(:right)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :low,
        x_position: 7.25,
        y_position: 9.0
      }

      assert actual === expected
    end
  end

  describe "change_speed" do
    test "speedup from rest" do
      actual =
        Fixtures.car(%{speed: :rest})
        |> Car.change_speed(:speedup)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :low,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "speedup from low speed" do
      actual =
        Fixtures.car(%{speed: :low})
        |> Car.change_speed(:speedup)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :moderate,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "speedup from moderate speed" do
      actual =
        Fixtures.car(%{speed: :moderate})
        |> Car.change_speed(:speedup)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :high,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "speedup from high speed" do
      actual =
        Fixtures.car(%{speed: :high})
        |> Car.change_speed(:speedup)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :high,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "slowdown from high speed" do
      actual =
        Fixtures.car(%{speed: :high})
        |> Car.change_speed(:slowdown)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :moderate,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "slowdown from moderate speed" do
      actual =
        Fixtures.car(%{speed: :moderate})
        |> Car.change_speed(:slowdown)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :low,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "slowdown from low speed" do
      actual =
        Fixtures.car(%{speed: :low})
        |> Car.change_speed(:slowdown)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :rest,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end

    test "slowdown from rest" do
      actual =
        Fixtures.car()
        |> Car.change_speed(:slowdown)

      expected = %Car{
        id: 1,
        controller: :player,
        image: "car.png",
        speed: :rest,
        x_position: 1.25,
        y_position: 9.0
      }

      assert actual === expected
    end
  end

  test "enable_speed_boost" do
    actual =
      Fixtures.car()
      |> Car.enable_speed_boost()

    expected = %Car{
      id: 1,
      controller: :player,
      image: "car.png",
      speed: :speed_boost,
      x_position: 1.25,
      y_position: 9.0
    }

    assert actual === expected
  end

  test "disable_speed_boost" do
    actual =
      Fixtures.car()
      |> Car.disable_speed_boost(:high)

    expected = %Car{
      id: 1,
      controller: :player,
      image: "car.png",
      speed: :high,
      x_position: 1.25,
      y_position: 9.0
    }

    assert actual === expected
  end

  describe "add_completion_time_if_finished" do
    test "finished" do
      pre_car = Fixtures.car(%{distance_travelled: 992.0})

      assert pre_car.completion_time === nil

      race = Fixtures.race()

      post_car = Car.add_completion_time_if_finished(pre_car, race)

      assert post_car.completion_time !== nil
    end

    test "not finished" do
      pre_car = Fixtures.car(%{distance_travelled: 500.0})

      assert pre_car.completion_time === nil

      race = Fixtures.race()

      post_car = Car.add_completion_time_if_finished(pre_car, race)

      assert post_car.completion_time === nil
    end
  end

  describe "get_lane" do
    test "within tracks" do
      actual =
        Fixtures.car()
        |> Car.get_lane()

      expected = 1

      assert actual === expected
    end

    test "out of tracks" do
      actual =
        Fixtures.car(%{x_position: -4.75})
        |> Car.get_lane()

      expected = :out_of_tracks

      assert actual === expected
    end
  end

  test "get_all_possible_ids" do
    actual = Car.get_all_possible_ids()

    expected = [1, 2, 3, 4, 5, 6]

    assert actual === expected
  end

  test "new" do
    actual =
      %{
        id: 4,
        image: "red.png",
        controller: :autonomous,
        x_position: 7.25,
        y_position: 7.0,
        speed: :high
      }
      |> Car.new()

    expected = %Car{
      id: 4,
      image: "red.png",
      controller: :autonomous,
      x_position: 7.25,
      y_position: 7.0,
      speed: :high
    }

    assert actual === expected
  end
end
