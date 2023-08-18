defmodule FormulaX.Race.CarController do
  @moduledoc """
  Module which controls all cars
  """
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.CrashDetection

  use GenServer

  ### Client API

  @doc """
  Start the controller.
  """
  # This has to be somehow made to keep driving the cars until race distance is reached by all cars. It is incomplete now.
  def start(race = %Race{}) do
    GenServer.start_link(__MODULE__, race, name: __MODULE__)
  end

  ###

  def steer_player_car(race = %Race{}, direction) do
    player_car = Race.get_player_car(race)

    case CrashDetection.crash?(race, player_car, direction) do
      true ->
        updated_player_car =
          player_car
          |> Car.steer(direction)
          |> Car.stop()

        race
        |> Race.update_cars(updated_player_car)
        |> Race.abort()

      false ->
        updated_player_car = Car.steer(player_car, direction)

        Race.update_cars(race, updated_player_car)
    end
  end

  def steer_computer_controlled_car(race = %Race{}, car, direction) do
    case CrashDetection.crash?(race, car, direction) do
      true ->
        race

      false ->
        updated_car = Car.steer(car, direction)

        Race.update_cars(race, updated_car)
    end
  end

  def drive_player_car(race = %Race{background: background}) do
    player_car = Race.get_player_car(race)

    # Background is moved in opposite direction to simulate car movement
    updated_background = Background.move(background, player_car.speed)

    case CrashDetection.crash?(race, player_car, :forward) do
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

  def drive_computer_controlled_car(
        race = %Race{},
        car = %Car{}
      ) do
    case CrashDetection.crash?(race, car, :forward) do
      true ->
        race

      false ->
        updated_car =
          car
          |> Car.drive()
          |> Car.adapt_car_position_with_reference_to_background(race)

        Race.update_cars(race, updated_car)
    end
  end

  ### GenServer API

  @doc """
  GenServer.init/1 callback
  """
  @impl true
  def init(race = %Race{}), do: {:ok, race}

  @doc """
  GenServer.handle_call/3 callback
  """
  @impl true
  def handle_call(:drive_cars, _from, race = %Race{}) do
    computer_controlled_cars = get_computer_controlled_cars(race)
    updated_race = drive_car(race, computer_controlled_cars)
    {:reply, :ok, updated_race}
  end

  ###

  defp drive_car(race = %Race{}, _computer_controlled_cars = [car]) do
    drive_computer_controlled_car(race, car)
  end

  defp drive_car(race = %Race{}, _computer_controlled_cars = [car | remaining_cars]) do
    updated_race = drive_computer_controlled_car(race, car)
    drive_car(updated_race, remaining_cars)
  end

  defp get_computer_controlled_cars(%Race{cars: cars}) do
    Enum.reject(cars, fn %Car{controller: controller} -> controller == :player end)
  end
end
