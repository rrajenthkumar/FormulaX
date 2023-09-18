defmodule FormulaX.CarControl do
  @moduledoc """
  **Car Control context**
  This module is the interface for all controls related to player and autonomous cars
  """
  alias FormulaX.CarControl.CrashDetection
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.RaceEngine

  @car_length Parameters.car_length()

  @doc """
  When the player car is driven, the car remains at same position
  and only the Background is moved in opposite direction, to give an illusion of forward movement.
  All autonomous cars' positions are adapted whenever the player car is driven forward.
  """
  @spec drive_player_car(Race.t()) :: Race.t()
  def drive_player_car(
        race = %Race{
          status: :paused
        }
      ) do
    race
  end

  def drive_player_car(
        race = %Race{
          background: background = %Background{},
          player_car: player_car = %Car{controller: :player}
        }
      ) do
    %Car{speed: player_car_speed} =
      updated_player_car =
      player_car
      |> Car.drive()
      |> Car.add_completion_time_if_finished(race)

    updated_background = Background.move(background, player_car_speed)

    race
    |> Race.update_player_car(updated_player_car)
    |> Race.update_background(updated_background)
    |> CrashDetection.update_crash_check_result(updated_player_car, _crash_check_side = :front)
    |> SpeedBoost.enable_if_fetched()
    |> Race.end_if_applicable()
  end

  @spec drive_autonomous_cars(Race.t()) :: Race.t()
  def drive_autonomous_cars(race = %Race{status: :paused}) do
    race
  end

  def drive_autonomous_cars(race = %Race{autonomous_cars: autonomous_cars}) do
    drive_autonomous_cars(autonomous_cars, race)
  end

  @spec steer_player_car(Race.t(), :left | :right) :: :ok
  def steer_player_car(
        race = %Race{player_car: player_car = %Car{controller: :player}},
        direction
      )
      when is_atom(direction) do
    updated_player_car = Car.steer(player_car, direction)

    race
    |> Race.update_player_car(updated_player_car)
    |> CrashDetection.update_crash_check_result(updated_player_car, _crash_check_side = direction)
    |> SpeedBoost.enable_if_fetched()
    |> RaceEngine.update()
  end

  @spec change_player_car_speed(Race.t(), :speedup | :slowdown) :: :ok
  def change_player_car_speed(
        race = %Race{player_car: player_car = %Car{controller: :player}},
        action
      )
      when is_atom(action) do
    updated_player_car = Car.change_speed(player_car, action)

    race
    |> Race.update_player_car(updated_player_car)
    |> RaceEngine.update()
  end

  @spec drive_autonomous_cars(list(Car.t()), Race.t()) :: Race.t()
  defp drive_autonomous_cars(
         [autonomous_car = %Car{controller: :autonomous}],
         race = %Race{}
       ) do
    drive_autonomous_car(race, autonomous_car)
  end

  defp drive_autonomous_cars(
         _autonomous_cars = [
           autonomous_car = %Car{controller: :autonomous} | remaining_autonomous_cars
         ],
         race = %Race{}
       ) do
    updated_race = drive_autonomous_car(race, autonomous_car)
    drive_autonomous_cars(remaining_autonomous_cars, updated_race)
  end

  @spec drive_autonomous_car(Race.t(), Car.t()) :: Race.t()
  defp drive_autonomous_car(race = %Race{}, autonomous_car = %Car{controller: :autonomous}) do
    updated_autonomous_car =
      autonomous_car
      |> Car.drive()
      |> Car.adapt_autonomous_car_position(race)
      |> Car.add_completion_time_if_finished(race)

    updated_race = Race.update_autonomous_car(race, updated_autonomous_car)

    case CrashDetection.crash?(updated_race, updated_autonomous_car, _crash_check_side = :front) do
      true ->
        steer_autonomous_car(race, autonomous_car)

      false ->
        updated_race
    end
  end

  @spec steer_autonomous_car(Race.t(), Car.t()) :: Race.t()
  defp steer_autonomous_car(race = %Race{}, autonomous_car = %Car{controller: :autonomous}) do
    direction = get_autonomous_car_steering_direction(race, autonomous_car)

    case direction do
      :noop ->
        race

      direction ->
        updated_autonomous_car = Car.steer(autonomous_car, direction)
        Race.update_autonomous_car(race, updated_autonomous_car)
    end
  end

  @spec get_autonomous_car_steering_direction(Race.t(), Car.t()) :: :left | :right | :noop
  defp get_autonomous_car_steering_direction(
         race = %Race{},
         querying_autonomous_car = %Car{controller: :autonomous}
       ) do
    lanes_cars_map = Race.get_lanes_and_cars_map(race)

    case Car.get_lane(querying_autonomous_car) do
      1 ->
        number_of_cars_in_vicinity_in_lane_2 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_autonomous_car, 2)

        case number_of_cars_in_vicinity_in_lane_2 do
          0 -> :right
          _others -> :noop
        end

      2 ->
        number_of_cars_in_vicinity_in_lane_1 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_autonomous_car, 1)

        number_of_cars_in_vicinity_in_lane_3 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_autonomous_car, 3)

        cond do
          number_of_cars_in_vicinity_in_lane_1 == 0 -> :left
          number_of_cars_in_vicinity_in_lane_3 == 0 -> :right
          true -> :noop
        end

      3 ->
        number_of_cars_in_vicinity_in_lane_2 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_autonomous_car, 2)

        case number_of_cars_in_vicinity_in_lane_2 do
          0 -> :left
          _others -> :noop
        end
    end
  end

  @spec number_of_adjacent_lane_cars_in_vicinity(map(), Car.t(), integer()) :: integer()
  defp number_of_adjacent_lane_cars_in_vicinity(
         lanes_cars_map,
         querying_autonomous_car = %Car{controller: :autonomous},
         adjacent_lane
       )
       when is_map(lanes_cars_map) and is_integer(adjacent_lane) do
    lanes_cars_map
    |> Map.get(adjacent_lane, [])
    |> adjacent_lane_cars_in_vicinity(querying_autonomous_car)
    |> length()
  end

  @spec adjacent_lane_cars_in_vicinity(list(Car.t()), Car.t()) :: list(Car.t())
  defp adjacent_lane_cars_in_vicinity(
         adjacent_lane_cars,
         %Car{y_position: querying_autonomous_car_y_position, controller: :autonomous}
       )
       when is_list(adjacent_lane_cars) do
    # We search for cars in the adjacent lane whose Y direction midpoint lies between half the car length behind the querying car to half the car length in front of the querying car.

    y_position_lower_limit_for_vicinity_check =
      querying_autonomous_car_y_position - @car_length / 2

    y_position_upper_limit_for_vicinity_check =
      querying_autonomous_car_y_position + @car_length +
        @car_length / 2

    Enum.filter(adjacent_lane_cars, fn %Car{y_position: adjacent_lane_car_y_position} ->
      adjacent_lane_car_midpoint_y_cordinate =
        adjacent_lane_car_y_position +
          @car_length / 2

      adjacent_lane_car_midpoint_y_cordinate >= y_position_lower_limit_for_vicinity_check and
        adjacent_lane_car_midpoint_y_cordinate <= y_position_upper_limit_for_vicinity_check
    end)
  end
end
