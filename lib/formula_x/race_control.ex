defmodule FormulaX.RaceControl do
  @moduledoc """
  Interface for all controls related to the Race.
  """
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle
  alias FormulaX.RaceControl.CrashDetection
  alias FormulaX.RaceEngine

  @car_length Parameters.car_length()
  @obstacle_length Parameters.obstacle_or_speed_boost_length()

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
    updated_player_car =
      player_car
      |> Car.drive()
      |> Car.add_completion_time_if_finished(race)

    updated_background = Background.move(background, updated_player_car)

    race
    |> Race.update_player_car(updated_player_car)
    |> Race.adapt_autonomous_cars_positions()
    |> Race.update_background(updated_background)
    |> Race.enable_speed_boost_if_fetched()
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
    |> Race.enable_speed_boost_if_fetched()
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

  @spec disable_speed_boost(Race.t()) :: :ok
  def disable_speed_boost(
        race = %Race{
          status: :ongoing,
          player_car: player_car = %Car{controller: :player, speed_boost_enabled?: true}
        }
      ) do
    updated_player_car = Car.disable_speed_boost(player_car)

    race
    |> Race.update_player_car(updated_player_car)
    |> RaceEngine.update()
  end

  @spec drive_autonomous_cars(Race.t()) :: Race.t()
  def drive_autonomous_cars(race = %Race{autonomous_cars: autonomous_cars}) do
    drive_autonomous_cars(autonomous_cars, race)
  end

  @spec drive_autonomous_cars(list(Car.t()), Race.t()) :: Race.t()
  defp drive_autonomous_cars(
         [autonomous_car = %Car{controller: :autonomous}],
         race = %Race{}
       ) do
    drive_autonomous_car(autonomous_car, race)
  end

  defp drive_autonomous_cars(
         _autonomous_cars = [
           autonomous_car = %Car{controller: :autonomous} | remaining_autonomous_cars
         ],
         race = %Race{}
       ) do
    updated_race = drive_autonomous_car(autonomous_car, race)
    drive_autonomous_cars(remaining_autonomous_cars, updated_race)
  end

  @spec drive_autonomous_car(Car.t(), Race.t()) :: Race.t()
  defp drive_autonomous_car(autonomous_car = %Car{controller: :autonomous}, race = %Race{}) do
    updated_autonomous_car =
      autonomous_car
      |> Car.drive()
      |> Car.adapt_autonomous_car_position(race)
      |> Car.add_completion_time_if_finished(race)

    updated_race = Race.update_autonomous_car(race, updated_autonomous_car)

    if CrashDetection.crash?(updated_race, updated_autonomous_car, :front) do
      steer_autonomous_car(race, autonomous_car)
    else
      updated_race
    end
  end

  @spec steer_autonomous_car(Race.t(), Car.t()) :: Race.t()
  defp steer_autonomous_car(race = %Race{}, autonomous_car = %Car{controller: :autonomous}) do
    autonomous_car_lane = Car.get_lane(autonomous_car)

    steering_direction =
      get_autonomous_car_steering_direction(race, autonomous_car, autonomous_car_lane)

    case steering_direction do
      :noop ->
        if CrashDetection.crash?(race, autonomous_car, :front) do
          steer_autonomous_car(race, autonomous_car)
        else
          race
        end

      steering_direction ->
        updated_autonomous_car = Car.steer(autonomous_car, steering_direction)
        Race.update_autonomous_car(race, updated_autonomous_car)
    end
  end

  @spec get_autonomous_car_steering_direction(Race.t(), Car.t(), 1 | 2 | 3) ::
          :left | :right | :noop
  defp get_autonomous_car_steering_direction(
         race = %Race{},
         autonomous_car = %Car{controller: :autonomous},
         _autonomous_car_lane = 1
       ) do
    lanes_cars_map = CrashDetection.get_lanes_and_cars_map(race)

    number_of_cars_in_vicinity_in_lane_2 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 2)

    if number_of_cars_in_vicinity_in_lane_2 === 0 and
         no_target_lane_obstacles_in_vicinity?(race, autonomous_car, 2) do
      :right
    else
      :noop
    end
  end

  defp get_autonomous_car_steering_direction(
         race = %Race{},
         autonomous_car = %Car{controller: :autonomous},
         _autonomous_car_lane = 2
       ) do
    lanes_cars_map = CrashDetection.get_lanes_and_cars_map(race)

    number_of_cars_in_vicinity_in_lane_1 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 1)

    number_of_cars_in_vicinity_in_lane_3 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 3)

    cond do
      number_of_cars_in_vicinity_in_lane_1 === 0 and
          no_target_lane_obstacles_in_vicinity?(race, autonomous_car, 1) ->
        :left

      number_of_cars_in_vicinity_in_lane_3 === 0 and
          no_target_lane_obstacles_in_vicinity?(race, autonomous_car, 3) ->
        :right

      true ->
        :noop
    end
  end

  defp get_autonomous_car_steering_direction(
         race = %Race{},
         autonomous_car = %Car{controller: :autonomous},
         _autonomous_car_lane = 3
       ) do
    lanes_cars_map = CrashDetection.get_lanes_and_cars_map(race)

    number_of_cars_in_vicinity_in_lane_2 =
      number_of_adjacent_lane_cars_in_vicinity(autonomous_car, lanes_cars_map, 2)

    if number_of_cars_in_vicinity_in_lane_2 === 0 and
         no_target_lane_obstacles_in_vicinity?(race, autonomous_car, 2) do
      :left
    else
      :noop
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
    # We take adjacent lane cars in the region from one car length behind the querying autonomous car
    # to one car length in front of the querying autonomous car.
    Enum.reject(adjacent_lane_cars, fn car ->
      car.y_position < autonomous_car_y_position - @car_length or
        car.y_position > autonomous_car_y_position + 2 * @car_length
    end)
  end

  @spec no_target_lane_obstacles_in_vicinity?(Race.t(), Car.t(), 1 | 2 | 3) :: boolean()
  defp no_target_lane_obstacles_in_vicinity?(
         race = %Race{},
         %Car{
           y_position: autonomous_car_y_position,
           distance_travelled: distance_travelled_by_autonomous_car,
           controller: :autonomous
         },
         target_lane
       )
       when target_lane in [1, 2, 3] do
    target_lane_obstacles =
      race
      |> CrashDetection.get_lanes_and_obstacles_map()
      |> Map.get(target_lane, [])

    # Is there no obstacle in the area starting from '2 * @obstacle_or_speed_boost_length' behind car
    # until '2 * @obstacle_or_speed_boost_length' after car?
    Enum.all?(
      target_lane_obstacles,
      fn %Obstacle{distance: target_lane_obstacle_distance} ->
        target_lane_obstacle_distance <
          autonomous_car_y_position + distance_travelled_by_autonomous_car -
            3 * @obstacle_length or
          target_lane_obstacle_distance >
            autonomous_car_y_position + distance_travelled_by_autonomous_car + @car_length +
              2 * @obstacle_length
      end
    )
  end
end
