defmodule FormulaX.Race.CrashDetection do
  @moduledoc """
  This module will be used by Car Controller module to steer computer driven cars and
  by Race module to alert player car crash
  """
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @spec crash?(Race.t(), Car.t(), :forward | :left | :right) :: boolean()
  def crash?(
        race = %Race{},
        querying_car = %Car{
          x_position: querying_car_x_position,
          y_position: querying_car_y_position
        },
        movement_direction = :left
      ) do
    {lanes_and_cars_map, querying_car_lane} = get_crash_check_parameters(race, querying_car)

    case querying_car_lane do
      # Possibility of crash with a background item ouside the leftmost lane
      1 ->
        # '0' is the left side limit for first lane
        if querying_car_x_position <= 0 do
          true
        else
          false
        end

      # Lane 2 or 3
      # Possibility of crash with a car on the left side
      lane ->
        left_lane_cars = Map.get(lanes_and_cars_map, lane - 1, [])

        # We search for cars in the left side lane region starting from half the car length behind the querying car to half the car length in front of the querying car
        # 112px is the length of a car and the origin of car is at its left bottom edge

        y_positions_for_vicinity_check =
          (querying_car_y_position - div(112, 2))..(querying_car_y_position + 112 +
                                                      div(112, 2))

        left_lane_cars_in_the_vicinity =
          Enum.filter(left_lane_cars, fn %Car{y_position: left_lane_car_y_position} ->
            Enum.member?(
              y_positions_for_vicinity_check,
              # Mid point y value for the left lane car
              left_lane_car_y_position +
                div(112, 2)
            )
          end)

        querying_car_after_steering_left = Car.steer(querying_car, movement_direction)

        Enum.any?(left_lane_cars_in_the_vicinity, fn left_lane_car ->
          crash_between_cars?(
            querying_car_after_steering_left,
            left_lane_car,
            movement_direction
          )
        end)
    end
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{
          x_position: querying_car_x_position,
          y_position: querying_car_y_position
        },
        movement_direction = :right
      ) do
    {lanes_and_cars_map, querying_car_lane} = get_crash_check_parameters(race, querying_car)

    case querying_car_lane do
      # Possibility of crash with a background item ouside the rightmost lane
      4 ->
        # '230' is the right side limit for 3rd lane

        if 230 - querying_car_x_position <= 0 do
          true
        else
          false
        end

      # Lane 1 or 2
      # Possibility of crash with a car on the right side
      lane ->
        right_lane_cars = Map.get(lanes_and_cars_map, lane + 1, [])

        # We search for cars in the right side lane region starting from half the car length behind the querying car to half the car length in front of the querying car
        # 112px is the length of a car and the origin of car is at its left bottom edge

        y_positions_for_vicinity_check =
          (querying_car_y_position - div(112, 2))..(querying_car_y_position + 112 +
                                                      div(112, 2))

        right_lane_cars_in_the_vicinity =
          Enum.filter(right_lane_cars, fn %Car{y_position: right_lane_car_y_position} ->
            Enum.member?(
              y_positions_for_vicinity_check,
              # Mid point y value for the right lane car
              right_lane_car_y_position +
                div(112, 2)
            )
          end)

        querying_car_after_steering_right = Car.steer(querying_car, movement_direction)

        Enum.any?(right_lane_cars_in_the_vicinity, fn right_lane_car ->
          crash_between_cars?(
            querying_car_after_steering_right,
            right_lane_car,
            movement_direction
          )
        end)
    end
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{
          y_position: querying_car_y_position,
          speed: querying_car_speed
        },
        movement_direction = :forward
      ) do
    {lanes_and_cars_map, querying_car_lane} = get_crash_check_parameters(race, querying_car)

    same_lane_cars = Map.get(lanes_and_cars_map, querying_car_lane, []) -- [querying_car]

    # We search for cars in the same lane in the region starting from front tip of the car to 50px or 75px or 100px in front of the querying car
    # based on the distance a car can go per drive() call

    y_positions_for_vicinity_check =
      case querying_car_speed do
        :rest ->
          []

        :slow ->
          (querying_car_y_position + 112)..(querying_car_y_position + 112 + 50)

        :moderate ->
          (querying_car_y_position + 112)..(querying_car_y_position + 112 + 75)

        :high ->
          (querying_car_y_position + 112)..(querying_car_y_position + 112 + 100)
      end

    result =
      Enum.filter(same_lane_cars, fn %Car{y_position: same_lane_car_y_position} ->
        Enum.member?(
          y_positions_for_vicinity_check,
          same_lane_car_y_position
        )
      end)

    case result do
      [] ->
        false

      [car_in_the_front] ->
        querying_car_after_moving_forward = Car.drive(querying_car)

        crash_between_cars?(
          querying_car_after_moving_forward,
          car_in_the_front,
          movement_direction
        )
    end
  end

  @spec get_crash_check_parameters(Race.t(), Car.t()) :: {Car.t(), integer(), map()}
  defp get_crash_check_parameters(%Race{cars: cars}, querying_car) do
    querying_car_lane = Car.get_lane(querying_car)
    lanes_and_cars_map = Enum.group_by(cars, &Car.get_lane/1, & &1)

    {lanes_and_cars_map, querying_car_lane}
  end

  @spec crash_between_cars?(Car.t(), Car.t(), :left | :right | :forward) :: boolean()
  defp crash_between_cars?(querying_car = %Car{}, left_car = %Car{}, :left) do
    querying_car_all_except_right_border_coordinates =
      get_border_coordinates(querying_car, :front) ++
        get_border_coordinates(querying_car, :rear) ++ get_border_coordinates(querying_car, :left)

    left_car_all_except_left_border_coordinates =
      get_border_coordinates(left_car, :front) ++
        get_border_coordinates(left_car, :rear) ++ get_border_coordinates(left_car, :right)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_right_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(left_car_all_except_left_border_coordinates, querying_car_coordinate)
    end)
  end

  defp crash_between_cars?(querying_car = %Car{}, right_car = %Car{}, :right) do
    querying_car_all_except_left_border_coordinates =
      get_border_coordinates(querying_car, :front) ++
        get_border_coordinates(querying_car, :rear) ++
        get_border_coordinates(querying_car, :right)

    right_car_all_except_right_border_coordinates =
      get_border_coordinates(right_car, :front) ++
        get_border_coordinates(right_car, :rear) ++ get_border_coordinates(right_car, :left)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_left_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(right_car_all_except_right_border_coordinates, querying_car_coordinate)
    end)
  end

  defp crash_between_cars?(querying_car = %Car{}, car_in_the_front = %Car{}, :forward) do
    querying_car_all_except_rear_border_coordinates =
      get_border_coordinates(querying_car, :front) ++
        get_border_coordinates(querying_car, :left) ++
        get_border_coordinates(querying_car, :right)

    front_car_all_except_front_border_coordinates =
      get_border_coordinates(car_in_the_front, :rear) ++
        get_border_coordinates(car_in_the_front, :left) ++
        get_border_coordinates(car_in_the_front, :right)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_rear_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(front_car_all_except_front_border_coordinates, querying_car_coordinate)
    end)
  end

  @spec get_border_coordinates(Car.t(), :front | :rear | :left | :right) :: list(Car.coordinate())
  defp get_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :front
       ) do
    Enum.map(car_edge_x..(car_edge_x + 56), fn x -> {x, car_edge_y + 112} end)
  end

  defp get_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :rear
       ) do
    Enum.map(car_edge_x..(car_edge_x + 56), fn x -> {x, car_edge_y} end)
  end

  defp get_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :left
       ) do
    Enum.map(car_edge_y..(car_edge_y + 112), fn y -> {car_edge_x, y} end)
  end

  defp get_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :right
       ) do
    Enum.map(car_edge_y..(car_edge_y + 112), fn y -> {car_edge_x + 56, y} end)
  end
end
