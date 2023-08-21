defmodule FormulaX.Race.CrashDetection do
  @moduledoc """
  **Crash detection context**
  This module is used by the Car Controller module to detect crash between cars or between a car and a background item outside the lanes
  """
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Parameters

  @car_width Parameters.car_dimensions().width
  @car_length Parameters.car_dimensions().length
  @position_range_step Parameters.position_range_step()

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
        %{x_start: x_start} = get_lane_limits(querying_car_lane)

        if querying_car_x_position <= x_start do
          true
        else
          false
        end

      # Lane 2 or 3
      # Possibility of crash with a car on the left side
      lane ->
        left_lane_cars = Map.get(lanes_and_cars_map, lane - 1, [])

        # We search for cars in the left side lane region starting from half the car length behind the querying car to half the car length in front of the querying car.
        # The origin point of a car is at its left bottom edge.

        y_positions_for_vicinity_check =
          (querying_car_y_position - div(@car_length, 2))..(querying_car_y_position + @car_length +
                                                              div(@car_length, 2))//@position_range_step

        left_lane_cars_in_the_vicinity =
          Enum.filter(left_lane_cars, fn %Car{y_position: left_lane_car_y_position} ->
            Enum.member?(
              y_positions_for_vicinity_check,
              left_lane_car_y_position +
                div(@car_length, 2)
            )
          end)

        querying_car_after_moving_left = Car.move(querying_car, movement_direction)

        Enum.any?(left_lane_cars_in_the_vicinity, fn left_lane_car ->
          crash_between_cars?(
            querying_car_after_moving_left,
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
      3 ->
        %{x_end: x_end} = get_lane_limits(querying_car_lane)

        if x_end - querying_car_x_position <= 0 do
          true
        else
          false
        end

      # Lane 1 or 2
      # Possibility of crash with a car on the right side
      lane ->
        right_lane_cars = Map.get(lanes_and_cars_map, lane + 1, [])

        # We search for cars in the right side lane region starting from half the car length behind the querying car to half the car length in front of the querying car

        y_positions_for_vicinity_check =
          (querying_car_y_position - div(@car_length, 2))..(querying_car_y_position + @car_length +
                                                              div(@car_length, 2))//@position_range_step

        right_lane_cars_in_the_vicinity =
          Enum.filter(right_lane_cars, fn %Car{y_position: right_lane_car_y_position} ->
            Enum.member?(
              y_positions_for_vicinity_check,
              right_lane_car_y_position +
                div(@car_length, 2)
            )
          end)

        querying_car_after_moving_right = Car.move(querying_car, movement_direction)

        Enum.any?(right_lane_cars_in_the_vicinity, fn right_lane_car ->
          crash_between_cars?(
            querying_car_after_moving_right,
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
          speed: querying_car_speed,
          controller: querying_car_controller
        },
        movement_direction = :forward
      ) do
    {lanes_and_cars_map, querying_car_lane} = get_crash_check_parameters(race, querying_car)

    same_lane_cars = Map.get(lanes_and_cars_map, querying_car_lane, []) -- [querying_car]

    # We search for cars in the same lane in the region starting from front tip of the car to car forward movement step value in front of the querying car

    y_positions_for_vicinity_check =
      case querying_car_speed do
        :rest ->
          []

        _others ->
          car_forward_movement_step = Parameters.car_forward_movement_step(querying_car_speed)

          (querying_car_y_position + @car_length)..(querying_car_y_position + @car_length +
                                                      car_forward_movement_step)//@position_range_step
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
        querying_car_after_moving_forward =
          case querying_car_controller do
            :computer ->
              Car.move(querying_car, :forward)
              |> Car.adapt_car_position_with_reference_to_background(race)

            :player ->
              Car.move(querying_car, :forward)
          end

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
      get_car_border_coordinates(querying_car, :front) ++
        get_car_border_coordinates(querying_car, :rear) ++
        get_car_border_coordinates(querying_car, :left)

    left_car_all_except_left_border_coordinates =
      get_car_border_coordinates(left_car, :front) ++
        get_car_border_coordinates(left_car, :rear) ++
        get_car_border_coordinates(left_car, :right)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_right_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(left_car_all_except_left_border_coordinates, querying_car_coordinate)
    end)
  end

  defp crash_between_cars?(querying_car = %Car{}, right_car = %Car{}, :right) do
    querying_car_all_except_left_border_coordinates =
      get_car_border_coordinates(querying_car, :front) ++
        get_car_border_coordinates(querying_car, :rear) ++
        get_car_border_coordinates(querying_car, :right)

    right_car_all_except_right_border_coordinates =
      get_car_border_coordinates(right_car, :front) ++
        get_car_border_coordinates(right_car, :rear) ++
        get_car_border_coordinates(right_car, :left)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_left_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(right_car_all_except_right_border_coordinates, querying_car_coordinate)
    end)
  end

  defp crash_between_cars?(querying_car = %Car{}, car_in_the_front = %Car{}, :forward) do
    querying_car_all_except_rear_border_coordinates =
      get_car_border_coordinates(querying_car, :front) ++
        get_car_border_coordinates(querying_car, :left) ++
        get_car_border_coordinates(querying_car, :right)

    front_car_all_except_front_border_coordinates =
      get_car_border_coordinates(car_in_the_front, :rear) ++
        get_car_border_coordinates(car_in_the_front, :left) ++
        get_car_border_coordinates(car_in_the_front, :right)

    # To check for an intersection between possibly crashing sides
    querying_car_all_except_rear_border_coordinates
    |> Enum.any?(fn querying_car_coordinate ->
      Enum.member?(front_car_all_except_front_border_coordinates, querying_car_coordinate)
    end)
  end

  @spec get_car_border_coordinates(Car.t(), :front | :rear | :left | :right) ::
          list(Car.coordinates())
  defp get_car_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :front
       ) do
    Enum.map(car_edge_x..(car_edge_x + @car_width)//@position_range_step, fn x ->
      {x, car_edge_y + @car_length}
    end)
  end

  defp get_car_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :rear
       ) do
    Enum.map(car_edge_x..(car_edge_x + @car_width)//@position_range_step, fn x ->
      {x, car_edge_y}
    end)
  end

  defp get_car_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :left
       ) do
    Enum.map(car_edge_y..(car_edge_y + @car_length)//@position_range_step, fn y ->
      {car_edge_x, y}
    end)
  end

  defp get_car_border_coordinates(
         %Car{x_position: car_edge_x, y_position: car_edge_y},
         :right
       ) do
    Enum.map(car_edge_y..(car_edge_y + @car_length)//@position_range_step, fn y ->
      {car_edge_x + @car_width, y}
    end)
  end

  @spec get_lane_limits(integer()) :: map()
  defp get_lane_limits(lane) do
    Parameters.lanes()
    |> Enum.find(fn %{lane_number: lane_number} -> lane_number == lane end)
  end
end
