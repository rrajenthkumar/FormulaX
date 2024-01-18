defmodule FormulaX.RaceControl.CrashDetection do
  @moduledoc """
  Used to detect crash with a car or an obstacle.
  """

  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle

  @car_length Parameters.car_length()
  @obstacle_length Parameters.obstacle_and_speed_boost_length()

  @doc """
  Please note that the race and car structs passed into this function have already been updated with the forward or sideward movement for which the possibility of crash is checked.
  The term 'querying car' in this module refers to the car that is requesting the crash check.
  """
  @spec crash?(Race.t(), Car.t(), :front | :left | :right) :: boolean()
  def crash?(
        race = %Race{},
        querying_car = %Car{},
        crash_check_side = :front
      ) do
    crash_with_car?(race, querying_car, crash_check_side) or
      crash_with_obstacle?(race, querying_car)
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{},
        crash_check_side
      )
      when crash_check_side in [:left, :right] do
    crash_with_car?(race, querying_car, crash_check_side) or
      crash_with_obstacle?(race, querying_car) or
      out_of_tracks?(querying_car)
  end

  @spec get_lanes_and_cars_map(Race.t()) :: map()
  def get_lanes_and_cars_map(%Race{
        player_car: player_car = %Car{controller: :player},
        autonomous_cars: autonomous_cars
      }) do
    lanes_and_autonomous_cars_map = Enum.group_by(autonomous_cars, &Car.get_lane/1, & &1)

    player_car_lane = Car.get_lane(player_car)

    autonomous_cars_in_player_car_lane =
      Map.get(lanes_and_autonomous_cars_map, player_car_lane, [])

    Map.put(
      lanes_and_autonomous_cars_map,
      player_car_lane,
      autonomous_cars_in_player_car_lane ++ [player_car]
    )
  end

  # Crash check with another car
  @spec crash_with_car?(Race.t(), Car.t(), :front | :left | :right) :: boolean()
  defp crash_with_car?(race = %Race{}, querying_car = %Car{}, _crash_check_side = :front) do
    race
    |> get_same_lane_cars(querying_car)
    |> remove_cars_behind(querying_car)
    |> Enum.any?(fn car -> cars_are_overlapping?(car, querying_car) end)
  end

  defp crash_with_car?(race = %Race{}, querying_car = %Car{}, crash_check_side)
       when crash_check_side in [:left, :right] do
    race
    # Since the movement that could possibly cause the crash has already happened the crashable car will be in the same lane as the querying car
    |> get_same_lane_cars(querying_car)
    |> Enum.any?(fn car -> cars_are_overlapping?(car, querying_car) end)
  end

  @spec get_same_lane_cars(Race.t(), Car.t()) :: list(Car.t())
  defp get_same_lane_cars(
         race = %Race{},
         querying_car = %Car{
           id: querying_car_id
         }
       ) do
    querying_car_lane = Car.get_lane(querying_car)

    race
    |> get_lanes_and_cars_map()
    |> Map.get(querying_car_lane, [])
    |> Enum.reject(fn car -> car.id == querying_car_id end)
  end

  @spec remove_cars_behind(list(Car.t()), Car.t()) :: list(Car.t())
  defp remove_cars_behind(
         same_lane_cars,
         %Car{y_position: querying_car_y_position}
       )
       when is_list(same_lane_cars) do
    Enum.reject(same_lane_cars, fn car ->
      car.y_position < querying_car_y_position
    end)
  end

  @spec cars_are_overlapping?(Car.t(), Car.t()) :: boolean()
  defp cars_are_overlapping?(%Car{y_position: car_1_y_position}, %Car{
         y_position: car_2_y_position
       }) do
    # Both cars are at the same position or
    # Car_1 front wheels between Car_2 front and rear wheels or
    # Car_1 rear wheels between Car_2 front and rear wheels
      (car_1_y_position + @car_length >= car_2_y_position and
         car_1_y_position <= car_2_y_position) or
      (car_1_y_position >= car_2_y_position and
         car_1_y_position <= car_2_y_position + @car_length)
  end

  # Crash check with an obstacle
  @spec crash_with_obstacle?(Race.t(), Car.t()) :: boolean()
  defp crash_with_obstacle?(
         race = %Race{},
         querying_car = %Car{}
       ) do
    race
    # Since the movement that could possibly cause the crash has already happened the crashable obstacle will be in the same lane as the querying car
    |> get_same_lane_obstacles(querying_car)
    |> Enum.any?(fn obstacle ->
      obstacle_y_position = Obstacle.get_y_position(obstacle, race)
      overlaps_with_obstacle?(querying_car, obstacle_y_position)
    end)
  end

  @spec get_same_lane_obstacles(Race.t(), Car.t()) :: list(Obstacle.t())
  defp get_same_lane_obstacles(
         race = %Race{},
         querying_car = %Car{}
       ) do
    querying_car_lane = Car.get_lane(querying_car)

    race
    |> get_lanes_and_obstacles_map()
    |> Map.get(querying_car_lane, [])
  end

  @spec get_lanes_and_obstacles_map(Race.t()) :: map()
  defp get_lanes_and_obstacles_map(%Race{obstacles: obstacles}) do
    Enum.group_by(obstacles, &Obstacle.get_lane/1, & &1)
  end

  @spec overlaps_with_obstacle?(Car.t(), Parameters.rem()) :: boolean()
  defp overlaps_with_obstacle?(%Car{y_position: car_y_position}, obstacle_y_position)
       when is_float(obstacle_y_position) do
    # Car and obstacle are at the same position or
    # Car front wheels between obstacle start and end or
    # Car rear wheels between obstacle start and end
      (car_y_position + @car_length >= obstacle_y_position and
         car_y_position <= obstacle_y_position) or
      (car_y_position >= obstacle_y_position and
         car_y_position <= obstacle_y_position + @obstacle_length)
  end

  # Car out of tracks
  defp out_of_tracks?(querying_car = %Car{}) do
    Car.get_lane(querying_car) == :out_of_tracks
  end
end
