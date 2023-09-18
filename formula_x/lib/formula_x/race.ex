defmodule FormulaX.Race do
  @moduledoc """
  Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle
  alias FormulaX.Race.SpeedBoost

  @race_distance Parameters.race_distance()
  @console_screen_height Parameters.console_screen_height()

  @type status :: :countdown | :ongoing | :paused | :crash | :completed

  @typedoc "Race struct"
  typedstruct do
    field(:player_car, Car.t(), enforce: true)
    field(:autonomous_cars, list(Car.t()), enforce: true)
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
  def initialize(player_car_index) when is_integer(player_car_index) do
    player_car = Car.initialize_player_car(player_car_index)
    autonomous_cars = Car.initialize_autonomous_cars(player_car)
    background = Background.initialize(@race_distance)
    obstacles = Obstacle.initialize_obstacles(@race_distance)
    speed_boosts = SpeedBoost.initialize_speed_boosts(@race_distance)

    new(%{
      player_car: player_car,
      autonomous_cars: autonomous_cars,
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
  def update_background(race = %Race{status: :ongoing}, updated_background = %Background{}) do
    %Race{race | background: updated_background}
  end

  @spec update_player_car(Race.t(), Car.t()) :: Race.t()
  def update_player_car(
        race = %Race{status: :ongoing},
        updated_player_car = %Car{controller: :player}
      ) do
    %Race{race | player_car: updated_player_car}
  end

  @spec update_autonomous_car(Race.t(), Car.t()) :: Race.t()
  def update_autonomous_car(
        race = %Race{autonomous_cars: autonomous_cars, status: :ongoing},
        updated_autonomous_car = %Car{id: updated_autonomous_car_id, controller: :autonomous}
      ) do
    updated_autonomous_cars =
      Enum.map(autonomous_cars, fn autonomous_car ->
        if autonomous_car.id == updated_autonomous_car_id do
          updated_autonomous_car
        else
          autonomous_car
        end
      end)

    %Race{race | autonomous_cars: updated_autonomous_cars}
  end

  @spec record_crash(Race.t()) :: Race.t()
  def record_crash(race = %Race{status: :ongoing}) do
    %Race{race | status: :crash}
  end

  @doc """
   Check used to stop the RaceEngine.
  """
  @spec player_car_past_finish?(Race.t()) :: boolean
  def player_car_past_finish?(%Race{
        distance: race_distance,
        player_car: %Car{
          distance_travelled: distance_travelled_by_player_car,
          controller: :player
        },
        status: :ongoing
      }) do
    # To check if the player car has travelled a distance of half the console screen height beyond the finish line. This particular distance is just to make the end look smooth.
    distance_travelled_by_player_car > race_distance + @console_screen_height / 2
  end

  @spec pause(Race.t()) :: Race.t()
  def pause(
        race = %Race{
          status: :ongoing
        }
      ) do
    %Race{race | status: :paused}
  end

  @spec unpause(Race.t()) :: Race.t()
  def unpause(
        race = %Race{
          status: :paused
        }
      ) do
    %Race{race | status: :ongoing}
  end

  @spec end_if_completed(Race.t()) :: Race.t()
  def end_if_completed(
        race = %Race{
          player_car: %Car{completion_time: nil, controller: :player},
          status: :ongoing
        }
      ) do
    race
  end

  def end_if_completed(
        race = %Race{
          player_car: %Car{controller: :player},
          status: :ongoing
        }
      ) do
    %Race{race | status: :completed}
  end

  @spec get_autonomous_car_by_id(Race.t(), integer()) :: Car.t() | nil
  def get_autonomous_car_by_id(
        %Race{autonomous_cars: autonomous_cars},
        searched_autonomous_car_id
      )
      when is_integer(searched_autonomous_car_id) do
    Enum.find(autonomous_cars, fn autonomous_car ->
      autonomous_car.id == searched_autonomous_car_id
    end)
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

  @spec get_lanes_and_obstacles_map(Race.t()) :: map()
  def get_lanes_and_obstacles_map(%Race{obstacles: obstacles}) do
    Enum.group_by(obstacles, &Obstacle.get_lane/1, & &1)
  end

  @spec get_lanes_and_speed_boosts_map(Race.t()) :: map()
  def get_lanes_and_speed_boosts_map(%Race{speed_boosts: speed_boosts}) do
    Enum.group_by(speed_boosts, &SpeedBoost.get_lane/1, & &1)
  end
end
