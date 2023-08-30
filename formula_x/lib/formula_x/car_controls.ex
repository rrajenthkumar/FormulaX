defmodule FormulaX.CarControls do
  @moduledoc """
  **Car Control context**
  This module is the interface for all controls related to player and autonomous cars
  """
  alias FormulaX.CarControls.CrashDetection
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car

  @doc """
  In case of forward movement of the player car, the car remains at same position and only the Background is moved in opposite direction
  # to give an illusion of forward movement. Also all other cars positions are adapted based on this movement of the player car.
  """
  @spec move_player_car(Race.t(), :left | :right | :forward) :: Race.t()
  def move_player_car(race = %Race{background: background}, direction = :forward) do
    %Car{speed: speed} =
      updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.move(direction)
      |> Car.add_completion_time_if_finished(race)

    updated_background = Background.move(background, speed)

    race
    |> update_race_based_on_crash_check_result(updated_player_car, direction)
    |> Race.update_background(updated_background)
    |> Race.end_if_completed()
  end

  # Left or right side movement
  def move_player_car(race = %Race{}, direction) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.move(direction)

    race
    |> update_race_based_on_crash_check_result(updated_player_car, direction)
  end

  @spec move_autonomous_car(Race.t(), Car.t(), :left | :right | :forward) :: Race.t()

  # Left or right side movement
  def move_autonomous_car(race = %Race{}, car = %Car{}, direction) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car = Car.move(car, direction)

        race
        |> Race.update_car(updated_car)
    end
  end

  defp move_autonomous_car(race = %Race{}, car = %Car{}, direction = :forward) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car =
          car
          |> Car.move(direction)
          |> Car.adapt_autonomous_car_y_position(race)
          |> Car.add_completion_time_if_finished(race)

        Race.update_car(race, updated_car)
    end
  end

  @spec move_autonomous_cars_forward(Race.t()) :: Race.t()
  def move_autonomous_cars_forward(race = %Race{}) do
    race
    |> Race.get_all_autonomous_cars()
    |> move_autonomous_cars_forward(race)
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
  def change_car_speed(race = %Race{}, car = %Car{car_id: car_id}, action) do
    updated_car =
      race
      |> Race.get_car(car_id)
      |> Car.change_speed(action)

    Race.update_car(race, updated_car)
  end

  @spec update_race_based_on_crash_check_result(Race.t(), Car.t(), :left | :right | :forward) ::
          Race.t()
  defp update_race_based_on_crash_check_result(
         race = %Race{},
         updated_player_car = %Car{controller: :player},
         direction = :forward
       ) do
    # We need this step so that all the other cars are at the correct position w.r.t the updated player car
    race_updated_for_check =
      race
      |> Race.update_car(updated_player_car)
      |> adapt_autonomous_cars_y_position()

    case CrashDetection.crash?(race_updated_for_check, updated_player_car, direction) do
      true ->
        race
        |> Race.update_car(updated_player_car)
        |> Race.record_crash()

      false ->
        race_updated_for_check
    end
  end

  defp update_race_based_on_crash_check_result(
         race = %Race{},
         updated_player_car = %Car{controller: :player},
         direction
       ) do
    case CrashDetection.crash?(race, updated_player_car, direction) do
      true ->
        race
        |> Race.update_car(updated_player_car)
        |> Race.record_crash()

      false ->
        race
        |> Race.update_car(updated_player_car)
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

  @spec move_autonomous_cars_forward(list(Car.t()), Race.t()) :: Race.t()
  defp move_autonomous_cars_forward(
         _autonomous_cars = [car],
         race = %Race{}
       ) do
    move_autonomous_car(race, car, :forward)
  end

  defp move_autonomous_cars_forward(
         _autonomous_cars = [car | remaining_cars],
         race = %Race{}
       ) do
    updated_race = move_autonomous_car(race, car, :forward)
    move_autonomous_cars_forward(remaining_cars, updated_race)
  end
end
