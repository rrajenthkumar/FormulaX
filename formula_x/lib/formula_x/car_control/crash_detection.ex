defmodule FormulaX.CarControl.CrashDetection do
  @moduledoc """
  **Crash detection context**
  This module is used by the Car Control module to detect crashes between cars and with background items
  Please note that every race struct and car struct mentioned in this module is already updated with the forward or sideward movement for which the possibility of crash is checked.
  """

  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle

  @car_length Parameters.car_length()
  @obstacle_length Parameters.stationary_items_length()

  @spec update_crash_check_result(Race.t(), Car.t(), :left | :right | :front) ::
          Race.t()
  def update_crash_check_result(
        race = %Race{},
        player_car = %Car{controller: :player},
        crash_check_side
      )
      when is_atom(crash_check_side) do
    case crash?(race, player_car, crash_check_side) do
      true ->
        Race.record_crash(race)

      false ->
        race
    end
  end

  @spec crash?(Race.t(), Car.t(), :front | :left | :right) :: boolean()
  def crash?(
        race = %Race{},
        querying_car = %Car{},
        _crash_check_side = :front
      ) do
    crash_check(race, querying_car)
  end

  def crash?(
        race = %Race{},
        querying_car = %Car{},
        crash_check_side
      )
      when is_atom(crash_check_side) do
    querying_car_lane = Car.get_lane(querying_car)

    case querying_car_lane do
      # Crash with a background item outside tracks
      :out_of_tracks ->
        true

      _querying_car_lane ->
        crash_check(race, querying_car)
    end
  end

  @spec crash_check(Race.t(), Car.t()) :: boolean()
  defp crash_check(race = %Race{}, querying_car = %Car{}) do
    race
    |> get_same_lane_cars(querying_car)
    |> overlapping_cars?(querying_car)
    |> case do
      false -> crash_with_obstacle?(race, querying_car)
      result -> result
    end
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
    |> Race.get_lanes_and_cars_map()
    |> Map.get(querying_car_lane, [])
    |> Enum.reject(fn same_lane_car -> same_lane_car.id == querying_car_id end)
  end

  @spec overlapping_cars?(list(Car.t()), Car.t()) :: boolean()
  defp overlapping_cars?(
         same_lane_cars,
         _querying_car = %Car{y_position: querying_car_y_position}
       )
       when is_list(same_lane_cars) do
    Enum.any?(same_lane_cars, fn %Car{y_position: same_lane_car_y_position} ->
      # Same lane car rear wheels between front and rear wheels of querying car or
      # same lane car front wheels between front and rear wheels of querying car
      (same_lane_car_y_position >= querying_car_y_position and
         same_lane_car_y_position <= querying_car_y_position + @car_length) or
        (same_lane_car_y_position + @car_length >= querying_car_y_position and
           same_lane_car_y_position <= querying_car_y_position)
    end)
  end

  @spec crash_with_obstacle?(Race.t(), Car.t()) :: boolean()
  defp crash_with_obstacle?(
         race = %Race{},
         querying_car = %Car{
           y_position: querying_car_y_position
         }
       ) do
    race
    |> get_same_lane_obstacles(querying_car)
    |> Enum.any?(fn obstacle ->
      obstacle_y_position = Obstacle.get_y_position(obstacle, race)

      # Car front wheels beyond obstacle starting y position and rear wheels behind obstacle starting y position or
      # Car rear wheels between obstacle starting and ending y positions
      (querying_car_y_position + @car_length >= obstacle_y_position and
         querying_car_y_position <= obstacle_y_position) or
        (querying_car_y_position >= obstacle_y_position and
           querying_car_y_position <=
             obstacle_y_position + @obstacle_length)
    end)
  end

  @spec get_same_lane_obstacles(Race.t(), Car.t()) :: list(Obstacle.t())
  defp get_same_lane_obstacles(
         race = %Race{},
         querying_car = %Car{}
       ) do
    querying_car_lane = Car.get_lane(querying_car)

    race
    |> Race.get_lanes_and_obstacles_map()
    |> Map.get(querying_car_lane, [])
  end
end
