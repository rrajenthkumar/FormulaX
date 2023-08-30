defmodule FormulaX.CarControl do
  @moduledoc """
  **Car Control context**
  This module is the interface for all controls related to player and autonomous cars
  """
  alias FormulaX.CarControl.CrashDetection
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car

  @doc """
  When the player car is driven, the car remains at same position and only the Background is moved in opposite direction
  # to give an illusion of forward movement. Also all other cars positions are adapted based on this movement of the player car.
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
    |> update_race_based_on_crash_check_result(updated_player_car, _crash_check_side = :front)
    |> Race.update_background(updated_background)
    |> Race.end_if_completed()
  end

  @spec steer_player_car(Race.t(), :left | :right) :: Race.t()
  def steer_player_car(race = %Race{}, direction) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.steer(direction)

    update_race_based_on_crash_check_result(
      race,
      updated_player_car,
      _crash_check_side = direction
    )
  end

  @spec steer_autonomous_car(Race.t(), Car.t(), :left | :right) :: Race.t()
  def steer_autonomous_car(race = %Race{}, car = %Car{}, direction) do
    updated_car = Car.steer(car, direction)

    case CrashDetection.crash?(race, updated_car, _crash_check_side = direction) do
      true ->
        race

      false ->
        Race.update_car(race, updated_car)
    end
  end

  @spec drive_autonomous_car(Race.t(), Car.t()) :: Race.t()
  defp drive_autonomous_car(race = %Race{}, car = %Car{}) do
    updated_car =
      car
      |> Car.drive()
      |> Car.adapt_autonomous_car_y_position(race)

    case CrashDetection.crash?(race, updated_car, _crash_check_side = :front) do
      true ->
        race

      false ->
        updated_car = Car.add_completion_time_if_finished(updated_car, race)

        Race.update_car(race, updated_car)
    end
  end

  @spec drive_autonomous_cars(Race.t()) :: Race.t()
  def drive_autonomous_cars(race = %Race{}) do
    race
    |> Race.get_all_autonomous_cars()
    |> drive_autonomous_cars(race)
  end

  @spec change_player_car_speed(Race.t(), :speedup | :slowdown) :: Race.t()
  def change_player_car_speed(race = %Race{}, action) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.change_speed(action)

    Race.update_car(race, updated_player_car)
  end

  @spec change_car_speed(Race.t(), Car.t(), :speedup | :slowdown) :: Race.t()
  def change_car_speed(race = %Race{}, %Car{car_id: car_id}, action) do
    updated_car =
      race
      |> Race.get_car(car_id)
      |> Car.change_speed(action)

    Race.update_car(race, updated_car)
  end

  @spec update_race_based_on_crash_check_result(Race.t(), Car.t(), :left | :right | :front) ::
          Race.t()
  defp update_race_based_on_crash_check_result(
         race = %Race{},
         updated_player_car = %Car{controller: :player},
         crash_check_side = :front
       ) do
    race_updated_for_check =
      race
      |> Race.update_car(updated_player_car)
      |> adapt_autonomous_cars_y_position()

    case CrashDetection.crash?(race_updated_for_check, updated_player_car, crash_check_side) do
      true ->
        Race.record_crash(race_updated_for_check)

      false ->
        race_updated_for_check
    end
  end

  defp update_race_based_on_crash_check_result(
         race = %Race{},
         updated_player_car = %Car{controller: :player},
         crash_check_side
       ) do
    case CrashDetection.crash?(race, updated_player_car, crash_check_side) do
      true ->
        race
        |> Race.update_car(updated_player_car)
        |> Race.record_crash()

      false ->
        Race.update_car(race, updated_player_car)
    end
  end

  @spec adapt_autonomous_cars_y_position(Race.t()) :: Race.t()
  defp adapt_autonomous_cars_y_position(race = %Race{}) do
    race
    |> Race.get_all_autonomous_cars()
    |> adapt_autonomous_cars_y_position(race)
  end

  @spec adapt_autonomous_cars_y_position(list(Car.t()), Race.t()) :: Race.t()
  defp adapt_autonomous_cars_y_position(
         _autonomous_cars = [car],
         race = %Race{}
       ) do
    adapted_car = Car.adapt_autonomous_car_y_position(car, race)
    Race.update_car(race, adapted_car)
  end

  defp adapt_autonomous_cars_y_position(
         _autonomous_cars = [car | remaining_cars],
         race = %Race{}
       ) do
    adapted_car = Car.adapt_autonomous_car_y_position(car, race)
    updated_race = Race.update_car(race, adapted_car)
    adapt_autonomous_cars_y_position(remaining_cars, updated_race)
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
end
