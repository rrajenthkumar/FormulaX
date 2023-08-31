defmodule FormulaX.CarControl.CrashDetection do
  @moduledoc """
  **Crash detection context**
  This module is used by the Car Control module to detect crashes between cars, with background items and with obstacles
  """
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Parameters

  @car_length Parameters.car_dimensions().length

  @spec crash?(Race.t(), Car.t(), :front | :left | :right) :: boolean()
  def crash?(
        race = %Race{},
        querying_car = %Car{x_position: querying_car_x_position},
        crash_check_side = :left
      ) do
    querying_car_lane = Car.get_lane(querying_car)

    case querying_car_lane do
      # Possibility of crash with a background item ouside the leftmost lane
      1 ->
        %{x_start: x_start} = get_lane_limits(querying_car_lane)

        if querying_car_x_position <= x_start do
          true
        else
          false
        end

      # Lane 2 or 3
      # Possibility of crash with a car on the left side
      querying_car_lane ->
        left_lane_cars_in_the_vicinity =
          race
          |> Race.get_lanes_and_cars_map()
          |> Map.get(querying_car_lane - 1, [])
          |> get_cars_in_vicinity(
            querying_car,
            crash_check_side
          )

        Enum.any?(left_lane_cars_in_the_vicinity, fn left_lane_car ->
          crash_between_cars?(
            querying_car,
            left_lane_car,
            crash_check_side
          )
        end)
    end
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{x_position: querying_car_x_position},
        crash_check_side = :right
      ) do
    querying_car_lane = Car.get_lane(querying_car)

    case querying_car_lane do
      # Possibility of crash with a background item ouside the rightmost lane
      3 ->
        %{x_end: x_end} = get_lane_limits(querying_car_lane)

        if x_end - querying_car_x_position <= 0 do
          true
        else
          false
        end

      # Lane 1 or 2
      # Possibility of crash with a car on the right side
      querying_car_lane ->
        right_lane_cars_in_the_vicinity =
          race
          |> Race.get_lanes_and_cars_map()
          |> Map.get(querying_car_lane + 1, [])
          |> get_cars_in_vicinity(
            querying_car,
            crash_check_side
          )

        Enum.any?(right_lane_cars_in_the_vicinity, fn right_lane_car ->
          crash_between_cars?(
            querying_car,
            right_lane_car,
            crash_check_side
          )
        end)
    end
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{
          car_id: querying_car_id
        },
        crash_check_side = :front
      ) do
    querying_car_lane = Car.get_lane(querying_car)

    cars_in_front =
      race
      |> Race.get_lanes_and_cars_map()
      |> Map.get(querying_car_lane, [])
      |> Enum.reject(fn same_lane_car -> same_lane_car.car_id == querying_car_id end)
      |> get_cars_in_vicinity(
        querying_car,
        crash_check_side
      )

    case cars_in_front do
      [] ->
        false

      front_cars ->
        Enum.any?(front_cars, fn front_car ->
          crash_between_cars?(
            querying_car,
            front_car,
            crash_check_side
          )
        end)
    end
  end

  @spec get_cars_in_vicinity(list(Car.t()), Car.t(), :left | :right | :front) :: list(Car.t())
  defp get_cars_in_vicinity(
         same_lane_cars,
         _querying_car = %Car{y_position: querying_car_y_position},
         _crash_check_side = :front
       ) do
    # We get the same lane cars within a distance of one car length in front of querying car if any.
    y_position_lower_limit_for_vicinity_check = querying_car_y_position + @car_length

    y_position_upper_limit_for_vicinity_check = querying_car_y_position + 2 * @car_length

    Enum.reject(same_lane_cars, fn same_lane_car ->
      same_lane_car.y_position >= y_position_lower_limit_for_vicinity_check and
        same_lane_car.y_position <= y_position_upper_limit_for_vicinity_check
    end)
  end

  defp get_cars_in_vicinity(
         adjacent_lane_cars,
         _querying_car = %Car{y_position: querying_car_y_position},
         _crash_check_side
       ) do
    # We search for cars in the left side lane region whose Y direction midpoint lies between half the car length behind the querying car to half the car length in front of the querying car.
    y_position_lower_limit_for_vicinity_check = querying_car_y_position - div(@car_length, 2)

    y_position_upper_limit_for_vicinity_check =
      querying_car_y_position + @car_length +
        div(@car_length, 2)

    Enum.filter(adjacent_lane_cars, fn %Car{y_position: adjacent_lane_car_y_position} ->
      adjacent_lane_car_midpoint_y_cordinate =
        adjacent_lane_car_y_position +
          div(@car_length, 2)

      adjacent_lane_car_midpoint_y_cordinate >= y_position_lower_limit_for_vicinity_check and
        adjacent_lane_car_midpoint_y_cordinate <= y_position_upper_limit_for_vicinity_check
    end)
  end

  @spec crash_between_cars?(Car.t(), Car.t(), :left | :right | :front) :: boolean()
  defp crash_between_cars?(querying_car = %Car{}, left_car = %Car{}, :left) do
    querying_car_all_except_right_border_coordinates =
      Car.get_side_coordinates(querying_car, :front) ++
        Car.get_side_coordinates(querying_car, :rear) ++
        Car.get_side_coordinates(querying_car, :left)

    left_car_all_except_left_border_coordinates =
      Car.get_side_coordinates(left_car, :front) ++
        Car.get_side_coordinates(left_car, :rear) ++
        Car.get_side_coordinates(left_car, :right)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_right_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(left_car_all_except_left_border_coordinates, querying_car_coordinate)
    end)
  end

  defp crash_between_cars?(querying_car = %Car{}, right_car = %Car{}, :right) do
    querying_car_all_except_left_border_coordinates =
      Car.get_side_coordinates(querying_car, :front) ++
        Car.get_side_coordinates(querying_car, :rear) ++
        Car.get_side_coordinates(querying_car, :right)

    right_car_all_except_right_border_coordinates =
      Car.get_side_coordinates(right_car, :front) ++
        Car.get_side_coordinates(right_car, :rear) ++
        Car.get_side_coordinates(right_car, :left)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_left_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(right_car_all_except_right_border_coordinates, querying_car_coordinate)
    end)
  end

  defp crash_between_cars?(querying_car = %Car{}, car_in_the_front = %Car{}, :front) do
    querying_car_all_except_rear_border_coordinates =
      Car.get_side_coordinates(querying_car, :front) ++
        Car.get_side_coordinates(querying_car, :left) ++
        Car.get_side_coordinates(querying_car, :right)

    front_car_all_except_front_border_coordinates =
      Car.get_side_coordinates(car_in_the_front, :rear) ++
        Car.get_side_coordinates(car_in_the_front, :left) ++
        Car.get_side_coordinates(car_in_the_front, :right)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_rear_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(front_car_all_except_front_border_coordinates, querying_car_coordinate)
    end)
  end

  @spec get_lane_limits(integer()) :: map()
  defp get_lane_limits(lane) do
    Parameters.lanes()
    |> Enum.find(fn %{lane_number: lane_number} -> lane_number == lane end)
  end
end
