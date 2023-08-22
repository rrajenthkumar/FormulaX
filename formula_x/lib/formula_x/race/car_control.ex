defmodule FormulaX.Race.CarControl do
  @moduledoc """
  **Car Control context**
  This module is an interface for all controls related to player and autonomous cars
  """
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.RaceEngine
  alias FormulaX.Race.CrashDetection

  @doc """
  In case of forward movement of the player car the Background is moved in opposite direction to simulate movement
  """
  @spec move_player_car(Race.t(), :forward) :: Race.t()
  def move_player_car(race = %Race{background: background}, direction = :forward) do
    player_car = Race.get_player_car(race)

    updated_background = Background.move(background, player_car.speed)

    case CrashDetection.crash?(race, player_car, direction) do
      true ->
        updated_player_car = Car.stop(player_car)

        race
        |> Race.update_background(updated_background)
        |> Race.update_car(updated_player_car)
        |> Race.abort()

      false ->
        Race.update_background(race, updated_background)
    end
  end

  # Left or right side movement
  @spec move_player_car(Race.t(), :left | :right) :: :ok
  def move_player_car(race = %Race{}, direction) do
    player_car = Race.get_player_car(race)

    updated_race =
      case CrashDetection.crash?(race, player_car, direction) do
        true ->
          updated_player_car =
            player_car
            |> Car.move(direction)
            |> Car.stop()

          race
          |> Race.update_car(updated_player_car)
          |> Race.abort()

        false ->
          updated_player_car = Car.move(player_car, direction)

          Race.update_car(race, updated_player_car)
      end

    RaceEngine.update_player_car(updated_race)
  end

  @spec change_player_car_speed(Race.t(), :speedup | :slowdown) :: Race.t()
  def change_player_car_speed(race = %Race{}, action) do
    player_car = Race.get_player_car(race)

    updated_player_car =
      player_car
      |> Car.change_speed(action)

    race
    |> Race.update_car(updated_player_car)
    |> RaceEngine.update_player_car()
  end

  @spec move_autonomous_cars(Race.t(), :left | :right | :forward) :: Race.t()
  def move_autonomous_cars(
        race = %Race{},
        direction
      ) do
    autonomous_cars = get_autonomous_cars(race)

    move_autonomous_cars(race, autonomous_cars, direction)
  end

  @spec move_autonomous_cars(Race.t(), list(Car.t()), :left | :right | :forward) :: Race.t()
  defp move_autonomous_cars(
         race = %Race{},
         _autonomous_cars = [car],
         direction
       ) do
    move_autonomous_car(race, car, direction)
  end

  defp move_autonomous_cars(
         race = %Race{},
         _autonomous_cars = [car | remaining_cars],
         direction
       ) do
    updated_race = move_autonomous_car(race, car, direction)
    move_autonomous_cars(updated_race, remaining_cars, direction)
  end

  @spec move_autonomous_car(Race.t(), Car.t(), :left | :right | :forward) :: Race.t()
  defp move_autonomous_car(race = %Race{}, car = %Car{}, direction = :forward) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car =
          car
          |> Car.move(direction)

        # |> Car.adapt_car_position_with_reference_to_background(race)

        Race.update_car(race, updated_car)
    end
  end

  defp move_autonomous_car(race = %Race{}, car = %Car{}, direction) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car = Car.move(car, direction)

        Race.update_car(race, updated_car)
    end
  end

  @spec get_autonomous_cars(Race.t()) :: list(Car.t())
  defp get_autonomous_cars(%Race{cars: cars}) do
    Enum.reject(cars, fn %Car{controller: controller} -> controller == :player end)
  end
end
