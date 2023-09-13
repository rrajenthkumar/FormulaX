defmodule FormulaX.Race do
  @moduledoc """
  **Race context**
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.Parameters

  @race_distance Parameters.race_distance()
  @console_screen_height Parameters.console_screen_height()

  @type cars :: list(Car.t())
  @type status :: :countdown | :ongoing | :crash | :completed

  @typedoc "Race struct"
  typedstruct do
    field(:cars, cars(), enforce: true)
    field(:background, Background.t(), enforce: true)
    field(:obstacles, list(Obstacle.t()), enforce: true)
    field(:speed_boosts, list(SpeedBoost.t()), enforce: true)
    field(:start_time, Time.t(), default: nil)
    field(:distance, Parameters.rem(), enforce: true)
    field(:status, status(), default: :countdown)
  end

  @spec new(map()) :: Race.t()
  def new(attrs) when is_map(attrs) do
    struct!(Race, attrs)
  end

  @spec initialize(integer()) :: Race.t()
  def initialize(player_car_index) do
    cars = Car.initialize_cars(player_car_index)
    background = Background.initialize(@race_distance)
    obstacles = Obstacle.initialize_obstacles(@race_distance)
    speed_boosts = SpeedBoost.initialize_speed_boosts(@race_distance)

    new(%{
      cars: cars,
      background: background,
      obstacles: obstacles,
      speed_boosts: speed_boosts,
      distance: @race_distance
    })
  end

  @spec start(Race.t()) :: Race.t()
  def start(race = %Race{status: :countdown}) do
    %Race{race | status: :ongoing, start_time: Time.utc_now()}
  end

  @spec update_background(Race.t(), Background.t()) :: Race.t()
  def update_background(race = %Race{}, updated_background = %Background{}) do
    %Race{race | background: updated_background}
  end

  @spec update_car(Race.t(), Car.t()) :: Race.t()
  def update_car(race = %Race{cars: cars}, updated_car = %Car{id: updated_car_id}) do
    updated_cars =
      Enum.map(cars, fn car ->
        if car.id == updated_car_id do
          updated_car
        else
          car
        end
      end)

    %Race{race | cars: updated_cars}
  end

  @spec record_crash(Race.t()) :: Race.t()
  def record_crash(race = %Race{}) do
    %Race{race | status: :crash}
  end

  @spec end_if_completed(Race.t()) :: boolean()
  def end_if_completed(race = %Race{}) do
    %Car{completion_time: player_car_completion_time} = get_player_car(race)

    cond do
      is_nil(player_car_completion_time) -> race
      true -> %Race{race | status: :completed}
    end
  end

  @spec get_car_by_id(Race.t(), integer()) :: {:ok, Car.t()} | {:error, String.t()}
  def get_car_by_id(%Race{cars: cars}, car_id) when is_integer(car_id) do
    result = Enum.find(cars, fn car -> car.id == car_id end)

    case result do
      nil -> {:error, "car not found"}
      result -> {:ok, result}
    end
  end

  @spec get_car(Race.t(), integer()) :: Car.t()
  def get_car(%Race{cars: cars}, car_id) do
    Enum.find(cars, fn car -> car.id == car_id end)
  end

  @spec get_player_car(Race.t()) :: Car.t()
  def get_player_car(%Race{cars: cars}) do
    Enum.find(cars, fn car -> car.controller == :player end)
  end

  @spec get_all_autonomous_cars(Race.t()) :: list(Car.t())
  def get_all_autonomous_cars(%Race{cars: cars}) do
    Enum.reject(cars, fn %Car{controller: controller} -> controller == :player end)
  end

  @doc """
   This function is used in RaceLive module to check and stop the RaceEngine.
  """
  @spec player_car_past_finish?(Race.t()) :: boolean
  def player_car_past_finish?(race = %Race{distance: race_distance}) do
    %Car{distance_travelled: distance_travelled_by_player_car} = get_player_car(race)

    # To check if the player car has travelled a distance of half the console screen height beyond the finish line (for cosmetic purpose)
    distance_travelled_by_player_car > race_distance + @console_screen_height / 2
  end

  @spec get_lanes_and_cars_map(Race.t()) :: map()
  def get_lanes_and_cars_map(%Race{cars: cars}) do
    Enum.group_by(cars, &Car.get_lane/1, & &1)
  end

  @spec get_lanes_and_obstacles_map(Race.t()) :: map()
  def get_lanes_and_obstacles_map(%Race{obstacles: obstacles}) do
    Enum.group_by(obstacles, &Obstacle.get_lane/1, & &1)
  end

  @spec get_lanes_and_speed_boost_map(Race.t()) :: map()
  def get_lanes_and_speed_boost_map(%Race{speed_boosts: speed_boosts}) do
    Enum.group_by(speed_boosts, &SpeedBoost.get_lane/1, & &1)
  end
end
