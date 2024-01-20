defmodule FormulaX.RaceControl do
  @moduledoc """
  Interface for all controls related to the Race.
  """
  alias FormulaX.RaceControl.CrashDetection
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.RaceEngine

  @car_length Parameters.car_length()

  @spec start_race(Race.t(), pid()) :: {:error, {:already_started, pid()}} | {:ok, pid()}
  def start_race(race = %Race{status: :countdown}, race_liveview_pid)
      when is_pid(race_liveview_pid) do
    race
    |> Race.start()
    |> RaceEngine.start(race_liveview_pid)
  end

  @doc """
  When the player car is driven, the car remains at same position
  and only the Background is moved in opposite direction, to give an illusion of forward movement.
  """
  @spec drive_player_car(Race.t()) :: Race.t()
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
    |> adapt_autonomous_cars_positions
    |> Race.update_background(updated_background)
    |> SpeedBoost.enable_if_fetched()
    |> Race.record_crash_if_applicable(_crash_check_side = :front)
    |> Race.end_if_applicable()
  end

  @spec steer_player_car(Race.t(), :left | :right) :: :ok
  def steer_player_car(
        race = %Race{player_car: player_car = %Car{controller: :player}},
        direction
      )
      when direction in [:left, :right] do
    updated_player_car = Car.steer(player_car, direction)

    race
    |> Race.update_player_car(updated_player_car)
    |> SpeedBoost.enable_if_fetched()
    |> Race.record_crash_if_applicable(_crash_check_side = direction)
    |> RaceEngine.update()
  end

  @spec change_player_car_speed(Race.t(), :speedup | :slowdown) :: :ok
  def change_player_car_speed(
        race = %Race{player_car: player_car = %Car{controller: :player}},
        action
      )
      when action in [:speedup, :slowdown] do
    updated_player_car = Car.change_speed(player_car, action)

    race
    |> Race.update_player_car(updated_player_car)
    |> RaceEngine.update()
  end

  @spec drive_autonomous_cars(Race.t()) :: Race.t()
  def drive_autonomous_cars(race = %Race{autonomous_cars: autonomous_cars}) do
    drive_autonomous_cars(autonomous_cars, race)
  end

  @spec pause_race(Race.t()) :: :ok
  def pause_race(race = %Race{status: :ongoing}) do
    race
    |> Race.pause()
    |> RaceEngine.update()
  end

  @spec unpause_race(Race.t()) :: :ok
  def unpause_race(race = %Race{status: :paused}) do
    race
    |> Race.unpause()
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
    lanes_cars_map = CrashDetection.get_lanes_and_cars_map(race)

    autonomous_car_lane = Car.get_lane(autonomous_car)

    direction =
      get_autonomous_car_steering_direction(autonomous_car, lanes_cars_map, autonomous_car_lane)

    case direction do
      :noop ->
        race

      direction ->
        updated_autonomous_car = Car.steer(autonomous_car, direction)
        Race.update_autonomous_car(race, updated_autonomous_car)
    end
  end

  @spec get_autonomous_car_steering_direction(Car.t(), map(), 1 | 2 | 3) :: :left | :right | :noop
  defp get_autonomous_car_steering_direction(
         autonomous_car = %Car{controller: :autonomous},
         lanes_cars_map = %{},
         _autonomous_car_lane = 1
       ) do
    number_of_cars_in_vicinity_in_lane_2 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 2)

    case number_of_cars_in_vicinity_in_lane_2 do
      0 -> :right
      _others -> :noop
    end
  end

  defp get_autonomous_car_steering_direction(
         autonomous_car = %Car{controller: :autonomous},
         lanes_cars_map = %{},
         _autonomous_car_lane = 2
       ) do
    number_of_cars_in_vicinity_in_lane_1 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 1)

    number_of_cars_in_vicinity_in_lane_3 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 3)

    cond do
      number_of_cars_in_vicinity_in_lane_1 == 0 -> :left
      number_of_cars_in_vicinity_in_lane_3 == 0 -> :right
      true -> :noop
    end
  end

  defp get_autonomous_car_steering_direction(
         autonomous_car = %Car{controller: :autonomous},
         lanes_cars_map = %{},
         _autonomous_car_lane = 3
       ) do
    number_of_cars_in_vicinity_in_lane_2 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 2)

    case number_of_cars_in_vicinity_in_lane_2 do
      0 -> :left
      _others -> :noop
    end
  end

  @spec number_of_adjacent_lane_cars_in_vicinity(Car.t(), map(), 1 | 2 | 3) :: integer()
  defp number_of_adjacent_lane_cars_in_vicinity(
         autonomous_car = %Car{controller: :autonomous},
         lanes_cars_map,
         adjacent_lane
       )
       when is_map(lanes_cars_map) and adjacent_lane in [1, 2, 3] do
    lanes_cars_map
    |> Map.get(adjacent_lane, [])
    |> adjacent_lane_cars_in_vicinity(autonomous_car)
    |> length()
  end

  @spec adjacent_lane_cars_in_vicinity(list(Car.t()), Car.t()) :: list(Car.t())
  defp adjacent_lane_cars_in_vicinity(
         adjacent_lane_cars,
         %Car{y_position: autonomous_car_y_position, controller: :autonomous}
       )
       when is_list(adjacent_lane_cars) do
    # We take adjacent lane cars in the region from one car length behind the querying autonomous car to one car length in front of the querying autonomous car.

    Enum.reject(adjacent_lane_cars, fn car ->
      car.y_position < autonomous_car_y_position - @car_length or
        car.y_position > autonomous_car_y_position + @car_length
    end)
  end

  @spec adapt_autonomous_cars_positions(Race.t()) :: Race.t()
  defp adapt_autonomous_cars_positions(race = %Race{autonomous_cars: autonomous_cars}) do
    adapt_autonomous_cars_positions(autonomous_cars, race)
  end

  @spec adapt_autonomous_cars_positions(list(Car.t()), Race.t()) :: Race.t()
  defp adapt_autonomous_cars_positions(
         [autonomous_car = %Car{controller: :autonomous}],
         race = %Race{}
       ) do
    updated_autonomous_car = Car.adapt_autonomous_car_position(autonomous_car, race)

    Race.update_autonomous_car(race, updated_autonomous_car)
  end

  defp adapt_autonomous_cars_positions(
         _autonomous_cars = [
           autonomous_car = %Car{controller: :autonomous} | remaining_autonomous_cars
         ],
         race = %Race{}
       ) do
    updated_autonomous_car = Car.adapt_autonomous_car_position(autonomous_car, race)
    updated_race = Race.update_autonomous_car(race, updated_autonomous_car)
    adapt_autonomous_cars_positions(remaining_autonomous_cars, updated_race)
  end
end
