defmodule FormulaX.CarControls do
  @moduledoc """
  **Car Control context**
  This module is the interface for all controls related to player and autonomous cars
  """
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.CarControls.CrashDetection

  @doc """
  In case of forward movement of the player car the Background is moved in opposite direction to simulate movement
  """
  @spec move_player_car(Race.t(), :left | :right | :forward) :: Race.t()
  def move_player_car(race = %Race{background: background}, direction = :forward) do
    %Car{speed: speed} =
      updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.move(direction)

    updated_background = Background.move(background, speed)

    race
    |> update_race_based_on_crash_check(updated_player_car, direction)
    |> Race.update_background(updated_background)
  end

  # Left or right side movement
  def move_player_car(race = %Race{}, direction) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.move(direction)

    race
    |> update_race_based_on_crash_check(updated_player_car, direction)
  end

  @spec move_autonomous_cars_forward(Race.t()) :: Race.t()
  def move_autonomous_cars_forward(race = %Race{}) do
    race
    |> get_autonomous_cars()
    |> move_autonomous_cars_forward(race)
  end

  @spec move_autonomous_car(Race.t(), Car.t(), :left | :right | :forward) :: Race.t()
  def move_autonomous_car(race = %Race{}, car = %Car{}, direction = :forward) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car =
          car
          |> Car.move(direction)
          |> Car.adapt_autonomous_car_y_position(race)

        Race.update_car(race, updated_car)
    end
  end

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

  @spec change_player_car_speed(Race.t(), :speedup | :slowdown) :: Race.t()
  def change_player_car_speed(race = %Race{}, action) do
    updated_player_car =
      race
      |> Race.get_player_car()
      |> Car.change_speed(action)

    Race.update_car(race, updated_player_car)
  end

  @spec update_race_based_on_crash_check(Race.t(), Car.t(), :left | :right | :forward) :: Race.t()
  defp update_race_based_on_crash_check(
         race = %Race{},
         player_car = %Car{controller: :player},
         direction
       ) do
    case CrashDetection.crash?(race, player_car, direction) do
      true ->
        updated_player_car = Car.stop(player_car)

        race
        |> Race.update_car(updated_player_car)
        |> Race.abort()

      false ->
        race
        |> Race.update_car(player_car)
    end
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

  @spec get_autonomous_cars(Race.t()) :: list(Car.t())
  defp get_autonomous_cars(%Race{cars: cars}) do
    Enum.reject(cars, fn %Car{controller: controller} -> controller == :player end)
  end
end
