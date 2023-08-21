defmodule FormulaX.Race.CarController do
  @moduledoc """
  **Car Controller context**
  This module takes care of controlling the player and computer controlled cars
  """
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.CarController.AutonomousDrivingServer
  alias FormulaX.Race.CrashDetection

  @doc """
  To start the Genserver.
  """
  def start(race = %Race{}, race_live_view_pid) do
    AutonomousDrivingServer.start(race, race_live_view_pid)
  end

  @doc """
  In case of forward movement of the player car the Background is moved in opposite direction to simulate movement
  """
  @spec move_player_car(Race.t(), :left | :right | :forward) :: Race.t()
  def move_player_car(race = %Race{background: background}, direction = :forward) do
    player_car = Race.get_player_car(race)

    updated_background = Background.move(background, player_car.speed)

    case CrashDetection.crash?(race, player_car, direction) do
      true ->
        updated_player_car = Car.stop(player_car)

        race
        |> Race.update_background(updated_background)
        |> Race.update_cars(updated_player_car)
        |> Race.abort()

      false ->
        Race.update_background(race, updated_background)
    end
  end

  # Left or right side movement
  def move_player_car(race = %Race{}, direction) do
    player_car = Race.get_player_car(race)

    case CrashDetection.crash?(race, player_car, direction) do
      true ->
        updated_player_car =
          player_car
          |> Car.move(direction)
          |> Car.stop()

        race
        |> Race.update_cars(updated_player_car)
        |> Race.abort()

      false ->
        updated_player_car = Car.move(player_car, direction)

        Race.update_cars(race, updated_player_car)
    end
  end

  @spec move_computer_controlled_cars(Race.t(), :left | :right | :forward) ::
          Race.t()
  def move_computer_controlled_cars(
        race = %Race{},
        direction
      ) do
    computer_controlled_cars = get_computer_controlled_cars(race)

    move_computer_controlled_cars(race, computer_controlled_cars, direction)
  end

  @spec move_computer_controlled_cars(Race.t(), list(Car.t()), :left | :right | :forward) ::
          Race.t()
  defp move_computer_controlled_cars(
         race = %Race{},
         _computer_controlled_cars = [car],
         direction
       ) do
    move_computer_controlled_car(race, car, direction)
  end

  defp move_computer_controlled_cars(
         race = %Race{},
         _computer_controlled_cars = [car | remaining_cars],
         direction
       ) do
    updated_race = move_computer_controlled_car(race, car, direction)
    move_computer_controlled_cars(updated_race, remaining_cars, direction)
  end

  @spec move_computer_controlled_car(Race.t(), Car.t(), :left | :right | :forward) :: Race.t()
  defp move_computer_controlled_car(race = %Race{}, car = %Car{}, direction = :forward) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car =
          car
          |> Car.move(direction)
          |> Car.adapt_car_position_with_reference_to_background(race)

        Race.update_cars(race, updated_car)
    end
  end

  defp move_computer_controlled_car(race = %Race{}, car = %Car{}, direction) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car = Car.move(car, direction)

        Race.update_cars(race, updated_car)
    end
  end

  @spec get_computer_controlled_cars(Race.t()) :: list(Car.t())
  defp get_computer_controlled_cars(%Race{cars: cars}) do
    Enum.reject(cars, fn %Car{controller: controller} -> controller == :player end)
  end
end
