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
          id: querying_car_id
        },
        crash_check_side = :front
      ) do
    querying_car_lane = Car.get_lane(querying_car)

    cars_in_front =
      race
      |> Race.get_lanes_and_cars_map()
      |> Map.get(querying_car_lane, [])
      |> Enum.reject(fn same_lane_car -> same_lane_car.id == querying_car_id end)
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

    Enum.filter(same_lane_cars, fn same_lane_car ->
      same_lane_car.y_position >= querying_car_y_position and
        same_lane_car.y_position <= querying_car_y_position + 2 * @car_length
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
    _querying_car_left_side_edge_coordinates =
      {{querying_car_left_side_rear_end_x, querying_car_left_side_rear_end_y},
       {_querying_car_left_side_front_end_x, querying_car_left_side_front_end_y}} =
      Car.get_side_edge_coordinates(querying_car, :left)

    _left_car_right_side_edge_coordinates =
      {{left_car_right_side_rear_end_x, left_car_right_side_rear_end_y},
       {_left_car_right_side_front_end_x, left_car_right_side_front_end_y}} =
      Car.get_side_edge_coordinates(left_car, :right)

    querying_car_left_side_rear_end_x <= left_car_right_side_rear_end_x and
      ((querying_car_left_side_front_end_y >= left_car_right_side_rear_end_y and
          querying_car_left_side_front_end_y <= left_car_right_side_front_end_y) or
         (querying_car_left_side_rear_end_y >= left_car_right_side_rear_end_y and
            querying_car_left_side_rear_end_y <= left_car_right_side_front_end_y))
  end

  defp crash_between_cars?(querying_car = %Car{}, right_car = %Car{}, :right) do
    _querying_car_right_side_edge_coordinates =
      {{querying_car_right_side_rear_end_x, querying_car_right_side_rear_end_y},
       {_querying_car_right_side_front_end_x, querying_car_right_side_front_end_y}} =
      Car.get_side_edge_coordinates(querying_car, :right)

    _right_car_left_side_edge_coordinates =
      {{right_car_left_side_rear_end_x, right_car_left_side_rear_end_y},
       {_right_car_left_side_front_end_x, right_car_left_side_front_end_y}} =
      Car.get_side_edge_coordinates(right_car, :left)

    querying_car_right_side_rear_end_x >= right_car_left_side_rear_end_x and
      ((querying_car_right_side_front_end_y >= right_car_left_side_rear_end_y and
          querying_car_right_side_front_end_y <= right_car_left_side_front_end_y) or
         (querying_car_right_side_rear_end_y >= right_car_left_side_rear_end_y and
            querying_car_right_side_rear_end_y <= right_car_left_side_front_end_y))
  end

  defp crash_between_cars?(querying_car = %Car{}, front_car = %Car{}, :front) do
    _querying_car_front_side_edge_coordinates =
      {{querying_car_front_side_left_end_x, querying_car_front_side_left_end_y},
       {querying_car_front_side_right_end_x, _querying_car_front_side_right_end_y}} =
      Car.get_side_edge_coordinates(querying_car, :front)

    _front_car_rear_side_edge_coordinates =
      {{front_car_rear_side_left_end_x, front_car_rear_side_left_end_y},
       {front_car_rear_side_right_end_x, _front_car_rear_side_right_end_y}} =
      Car.get_side_edge_coordinates(front_car, :rear)

    querying_car_front_side_left_end_y >= front_car_rear_side_left_end_y and
      ((querying_car_front_side_left_end_x >= front_car_rear_side_left_end_x and
          querying_car_front_side_left_end_x <= front_car_rear_side_right_end_x) or
         (querying_car_front_side_right_end_x >= front_car_rear_side_left_end_x and
            querying_car_front_side_right_end_x <= front_car_rear_side_right_end_x))
  end

  @spec get_lane_limits(integer()) :: map()
  defp get_lane_limits(lane) do
    Parameters.lanes()
    |> Enum.find(fn %{lane_number: lane_number} -> lane_number == lane end)
  end
end
