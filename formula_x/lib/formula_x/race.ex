defmodule FormulaX.Race do
  @moduledoc """
  The Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.CarControl.CrashDetection
  alias FormulaX.Parameters
  alias FormulaX.RaceEngine
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.Utils

  @race_distance Parameters.race_distance()
  @console_screen_height Parameters.console_screen_height()
  @obstacles_and_speed_boosts_free_distance Parameters.obstacles_and_speed_boosts_free_distance()
  @speed_boost_y_position_step Parameters.speed_boost_y_position_step()
  @max_obstacle_y_position_step Parameters.max_obstacle_y_position_step()

  @type status :: :countdown | :ongoing | :paused | :crash | :ended

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

  @spec initialize(integer()) :: Race.t()
  def initialize(player_car_index) when is_integer(player_car_index) do
    player_car = Car.initialize_player_car(player_car_index)
    autonomous_cars = initialize_autonomous_cars(player_car)
    background = Background.initialize(@race_distance)
    obstacles = initialize_obstacles(@race_distance)
    speed_boosts = initialize_speed_boosts(@race_distance)

    new(%{
      player_car: player_car,
      autonomous_cars: autonomous_cars,
      background: background,
      obstacles: obstacles,
      speed_boosts: speed_boosts,
      distance: @race_distance
    })
  end

  @spec start(Race.t(), pid()) :: Race.t()
  def start(race = %Race{status: :countdown}, race_liveview_pid) do
    started_race = %Race{race | status: :ongoing, start_time: Time.utc_now()}

    RaceEngine.start(started_race, race_liveview_pid)

    started_race
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

  @spec pause(Race.t()) :: :ok
  def pause(
        race = %Race{
          status: :ongoing
        }
      ) do
    %Race{race | status: :paused}
    |> RaceEngine.update()
  end

  @spec unpause(Race.t()) :: :ok
  def unpause(
        race = %Race{
          status: :paused
        }
      ) do
    %Race{race | status: :ongoing}
    |> RaceEngine.update()
  end

  @spec record_crash_if_applicable(Race.t(), :left | :right | :front) :: Race.t()
  def record_crash_if_applicable(
        race = %Race{status: :ongoing, player_car: player_car},
        crash_check_side
      )
      when crash_check_side in [:left, :right, :front] do
    case CrashDetection.crash?(race, player_car, crash_check_side) do
      true ->
        %Race{race | status: :crash}

      false ->
        race
    end
  end

  @spec end_if_applicable(Race.t()) :: Race.t()
  def end_if_applicable(race = %Race{status: :crash}) do
    race
  end

  def end_if_applicable(race = %Race{status: :ongoing}) do
    case player_car_past_finish?(race) do
      true ->
        %Race{race | status: :ended}

      false ->
        race
    end
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

  @spec initialize_autonomous_cars(Car.t()) :: list(Car.t())
  defp initialize_autonomous_cars(%Car{
         id: player_car_id,
         image: player_car_image,
         controller: :player
       }) do
    available_ids = Car.get_all_possible_ids() -- [player_car_id]
    available_car_images = Utils.get_filenames_of_images("cars") -- [player_car_image]

    initialize_autonomous_cars(available_ids, available_car_images)
  end

  @spec initialize_autonomous_cars(list(integer()), list(Car.filename())) :: list(Car.t())
  defp initialize_autonomous_cars([car_id], car_images)
       when is_integer(car_id) and is_list(car_images) do
    car_image = Enum.random(car_images)

    [Car.initialize_autonomous_car(car_id, car_image)]
  end

  defp initialize_autonomous_cars(_car_ids = [head | tail], car_images)
       when is_integer(head) and is_list(car_images) do
    car_image = Enum.random(car_images)

    car = Car.initialize_autonomous_car(head, car_image)

    remaining_car_images = car_images -- [car_image]

    [car] ++ initialize_autonomous_cars(tail, remaining_car_images)
  end

  @spec initialize_obstacles(Parameters.rem()) :: list(Obstacle.t())
  defp initialize_obstacles(race_distance) when is_float(race_distance) do
    %{distance: new_obstacle_distance} =
      new_obstacle = Obstacle.initialize_obstacle(@obstacles_and_speed_boosts_free_distance)

    [new_obstacle] ++
      initialize_obstacles(race_distance, new_obstacle_distance)
  end

  @spec initialize_obstacles(Parameters.rem(), Parameters.rem()) :: list(Obstacle.t()) | []
  defp initialize_obstacles(race_distance, distance_covered_with_obstacles)
       when is_float(race_distance) and is_float(distance_covered_with_obstacles) do
    cond do
      race_distance - distance_covered_with_obstacles < @max_obstacle_y_position_step ->
        []

      true ->
        %{distance: new_obstacle_distance} =
          new_obstacle = Obstacle.initialize_obstacle(distance_covered_with_obstacles)

        [new_obstacle] ++
          initialize_obstacles(race_distance, new_obstacle_distance)
    end
  end

  @spec initialize_speed_boosts(Parameters.rem()) :: list(SpeedBoost.t())
  defp initialize_speed_boosts(race_distance) when is_float(race_distance) do
    %{distance: new_speed_boost_distance} =
      new_speed_boost =
      SpeedBoost.initialize_speed_boost(@obstacles_and_speed_boosts_free_distance)

    [new_speed_boost] ++
      initialize_speed_boosts(race_distance, new_speed_boost_distance)
  end

  @spec initialize_speed_boosts(Parameters.rem(), Parameters.rem()) ::
          list(SpeedBoost.t()) | []
  defp initialize_speed_boosts(race_distance, distance_covered_with_speed_boosts)
       when is_float(race_distance) and is_float(distance_covered_with_speed_boosts) do
    cond do
      race_distance - distance_covered_with_speed_boosts <
          @speed_boost_y_position_step ->
        []

      true ->
        %{distance: new_speed_boost_distance} =
          new_speed_boost = SpeedBoost.initialize_speed_boost(distance_covered_with_speed_boosts)

        [new_speed_boost] ++
          initialize_speed_boosts(race_distance, new_speed_boost_distance)
    end
  end

  @spec new(map()) :: Race.t()
  defp new(attrs) when is_map(attrs) do
    struct!(Race, attrs)
  end

  @spec player_car_past_finish?(Race.t()) :: boolean
  defp player_car_past_finish?(%Race{
         distance: race_distance,
         player_car: %Car{
           distance_travelled: distance_travelled_by_player_car,
           controller: :player
         }
       }) do
    # To check if the player car has travelled a distance of half the console screen height beyond the finish line. This particular distance is just to make the end look smooth.
    distance_travelled_by_player_car > race_distance + @console_screen_height / 2
  end
end
