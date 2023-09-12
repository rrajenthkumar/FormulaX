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

  @car_length Parameters.car_dimensions().length

  @doc """
  When the player car is driven, the car remains at same position
  and only the Background is moved in opposite direction, to give an illusion of forward movement.
  All autonomous cars' positions are adapted whenever the player car is driven forward.
  """
  @spec drive_player_car(Race.t()) :: Race.t()
  def drive_player_car(race = %Race{background: background}) do
    %Car{speed: speed} =
      updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.drive()
      |> Car.add_completion_time_if_finished(race)

    updated_background = Background.move(background, speed)

    race
    |> Race.update_car(updated_player_car)
    |> Race.update_background(updated_background)
    |> adapt_autonomous_cars_positions()
    |> update_crash_check_result(updated_player_car, _crash_check_side = :front)
    |> enable_speed_boost_if_fetched()
    |> Race.end_if_completed()
  end

  @spec drive_autonomous_cars(Race.t()) :: Race.t()
  def drive_autonomous_cars(race = %Race{}) do
    race
    |> Race.get_all_autonomous_cars()
    |> drive_autonomous_cars(race)
  end

  @spec steer_player_car(Race.t(), :left | :right) :: :ok
  def steer_player_car(race = %Race{}, direction) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.steer(direction)

    race
    |> Race.update_car(updated_player_car)
    |> update_crash_check_result(updated_player_car, _crash_check_side = direction)
    |> enable_speed_boost_if_fetched()
    |> RaceEngine.update()
  end

  @spec change_player_car_speed(Race.t(), :speedup | :slowdown) :: :ok
  def change_player_car_speed(race = %Race{}, action) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.change_speed(action)

    race
    |> Race.update_car(updated_player_car)
    |> RaceEngine.update()
  end

  # Not used yet
  @spec change_autonomous_car_speed(Race.t(), Car.t(), :speedup | :slowdown) :: Race.t()
  def change_autonomous_car_speed(race = %Race{}, %Car{id: car_id}, action) do
    updated_car =
      race
      |> Race.get_car(car_id)
      |> Car.change_speed(action)

    Race.update_car(race, updated_car)
  end

  @spec update_crash_check_result(Race.t(), Car.t(), :left | :right | :front) ::
          Race.t()
  defp update_crash_check_result(
         race = %Race{},
         player_car = %Car{controller: :player},
         crash_check_side
       ) do
    case CrashDetection.crash?(race, player_car, crash_check_side) do
      true ->
        Race.record_crash(race)

      false ->
        race
    end
  end

  @spec drive_autonomous_cars(list(Car.t()), Race.t()) :: Race.t()
  defp drive_autonomous_cars(
         _autonomous_cars = [car],
         race = %Race{}
       ) do
    drive_autonomous_car(race, car)
  end

  defp drive_autonomous_cars(
         _autonomous_cars = [car | remaining_cars],
         race = %Race{}
       ) do
    updated_race = drive_autonomous_car(race, car)
    drive_autonomous_cars(remaining_cars, updated_race)
  end

  @spec drive_autonomous_car(Race.t(), Car.t()) :: Race.t()
  defp drive_autonomous_car(race = %Race{}, car = %Car{}) do
    updated_car =
      car
      |> Car.drive()
      |> Car.adapt_autonomous_car_position(race)
      |> Car.add_completion_time_if_finished(race)

    updated_race = Race.update_car(race, updated_car)

    case CrashDetection.crash?(updated_race, updated_car, _crash_check_side = :front) do
      true ->
        steer_autonomous_car(race, car)

      false ->
        updated_race
    end
  end

  @spec steer_autonomous_car(Race.t(), Car.t()) :: Race.t()
  defp steer_autonomous_car(race = %Race{}, car = %Car{}) do
    direction = get_autonomous_car_steering_direction(race, car)

    case direction do
      :noop ->
        race

      direction ->
        updated_car = Car.steer(car, direction)
        Race.update_car(race, updated_car)
    end
  end

  @spec get_autonomous_car_steering_direction(Race.t(), Car.t()) :: :left | :right | :noop
  defp get_autonomous_car_steering_direction(
         race = %Race{},
         querying_car = %Car{}
       ) do
    lanes_cars_map = Race.get_lanes_and_cars_map(race)

    case Car.get_lane(querying_car) do
      1 ->
        number_of_cars_in_vicinity_in_lane_2 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_car, 2)

        case number_of_cars_in_vicinity_in_lane_2 do
          0 -> :right
          _others -> :noop
        end

      2 ->
        number_of_cars_in_vicinity_in_lane_1 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_car, 1)

        number_of_cars_in_vicinity_in_lane_3 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_car, 3)

        cond do
          number_of_cars_in_vicinity_in_lane_1 == 0 -> :left
          number_of_cars_in_vicinity_in_lane_3 == 0 -> :right
          true -> :noop
        end

      3 ->
        number_of_cars_in_vicinity_in_lane_2 =
          number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_car, 2)

        case number_of_cars_in_vicinity_in_lane_2 do
          0 -> :left
          _others -> :noop
        end
    end
  end

  @spec number_of_adjacent_lane_cars_in_vicinity(map(), Car.t(), integer()) :: integer()
  defp number_of_adjacent_lane_cars_in_vicinity(lanes_cars_map, querying_car, adjacent_lane) do
    lanes_cars_map
    |> Map.get(adjacent_lane, [])
    |> adjacent_lane_cars_in_vicinity(querying_car)
    |> length()
  end

  @spec adjacent_lane_cars_in_vicinity(list(Car.t()), Car.t()) :: list(Car.t())
  defp adjacent_lane_cars_in_vicinity(
         adjacent_lane_cars,
         _querying_car = %Car{y_position: querying_car_y_position}
       ) do
    # We search for cars in the adjacent lane whose Y direction midpoint lies between half the car length behind the querying car to half the car length in front of the querying car.
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

  @spec adapt_autonomous_cars_positions(Race.t()) :: Race.t()
  defp adapt_autonomous_cars_positions(race = %Race{}) do
    race
    |> Race.get_all_autonomous_cars()
    |> adapt_autonomous_cars_positions(race)
  end

  @spec adapt_autonomous_cars_positions(list(Car.t()), Race.t()) :: Race.t()
  defp adapt_autonomous_cars_positions(
         _autonomous_cars = [car],
         race = %Race{}
       ) do
    adapted_car = Car.adapt_autonomous_car_position(car, race)
    Race.update_car(race, adapted_car)
  end

  defp adapt_autonomous_cars_positions(
         _autonomous_cars = [car | remaining_cars],
         race = %Race{}
       ) do
    adapted_car = Car.adapt_autonomous_car_position(car, race)
    updated_race = Race.update_car(race, adapted_car)
    adapt_autonomous_cars_positions(remaining_cars, updated_race)
  end

  @spec enable_speed_boost_if_fetched(Race.t()) :: Race.t()
  def enable_speed_boost_if_fetched(race = %Race{}) do
    case speed_boost_fetched?(race) do
      true ->
        updated_car =
          race
          |> Race.get_player_car()
          |> Car.enable_speed_boost()

        Race.update_car(race, updated_car)

      false ->
        race
    end
  end

  @spec speed_boost_fetched?(Race.t()) :: boolean()
  defp speed_boost_fetched?(race = %Race{}) do
    player_car =
      %Car{
        y_position: player_car_y_position
      } = Race.get_player_car(race)

    race
    |> get_same_lane_speed_boosts(player_car)
    |> Enum.any?(fn speed_boost ->
      speed_boost_y_position = SpeedBoost.get_y_position(speed_boost, race)

      # Car front wheels beyond speed boost starting y position and rear wheels behind speed boost starting y position or
      # Car rear wheels between speed boost starting and ending y positions
      (player_car_y_position + @car_length >= speed_boost_y_position and
         player_car_y_position <= speed_boost_y_position) or
        (player_car_y_position >= speed_boost_y_position and
           player_car_y_position <=
             speed_boost_y_position + Parameters.speed_boost_dimensions().length())
    end)
  end

  @spec get_same_lane_speed_boosts(Race.t(), Car.t()) :: list(SpeedBoost.t())
  defp get_same_lane_speed_boosts(
         race = %Race{},
         player_car = %Car{}
       ) do
    player_car_lane = Car.get_lane(player_car)

    race
    |> Race.get_lanes_and_speed_boost_map()
    |> Map.get(player_car_lane, [])
  end
end
