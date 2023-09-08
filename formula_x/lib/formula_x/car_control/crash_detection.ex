defmodule FormulaX.CarControl.CrashDetection do
  @moduledoc """
  **Crash detection context**
  This module is used by the Car Control module to detect crashes between cars, with background items
  Please note that all every race and car mentioned in this module are already updated with the forward or sideward movement for which the possibility of crash is checked.
  """
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Parameters

  @car_length Parameters.car_dimensions().length

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
        _crash_check_side
      ) do
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
  defp crash_check(race, querying_car) do
    race
    |> get_same_lane_cars(querying_car)
    |> overlapping_cars?(querying_car)
  end

  @spec get_same_lane_cars(Race.t(), Car.t()) :: list(Car.t())
  defp get_same_lane_cars(
         race,
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
       ) do
    Enum.find(same_lane_cars, fn same_lane_car ->
      # Same lane car rear wheels between front and rear wheels of querying car or
      # same lane car front wheels between front and rear wheels of querying car
      (same_lane_car.y_position >= querying_car_y_position and
         same_lane_car.y_position <= querying_car_y_position + @car_length) or
        (same_lane_car.y_position + @car_length >= querying_car_y_position and
           same_lane_car.y_position <= querying_car_y_position)
    end)
    |> case do
      nil ->
        false

      _overlapping_car ->
        true
    end
  end
end
