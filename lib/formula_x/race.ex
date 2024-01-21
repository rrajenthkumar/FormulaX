defmodule FormulaX.Race do
  @moduledoc """
  The Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.RaceControl.CrashDetection
  alias FormulaX.Utils

  @car_length Parameters.car_length()
  @race_distance Parameters.race_distance()
  @console_screen_height Parameters.console_screen_height()
  @obstacle_or_speed_boost_prohibited_distance Parameters.obstacle_or_speed_boost_prohibited_distance()
  @obstacle_or_speed_boost_length Parameters.obstacle_or_speed_boost_length()
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
  def initialize(player_car_image_index) when is_integer(player_car_image_index) do
    player_car = Car.initialize_player_car(player_car_image_index)
    autonomous_cars = initialize_autonomous_cars(player_car)
    background = Background.initialize(@race_distance)
    speed_boosts = initialize_speed_boosts(@race_distance)

    obstacles =
      @race_distance
      |> initialize_obstacles()
      |> remove_obstacles_in_the_vicinity_of_speedboosts(speed_boosts)

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
        race = %Race{autonomous_cars: autonomous_cars},
        updated_autonomous_car = %Car{id: updated_autonomous_car_id, controller: :autonomous}
      ) do
    updated_autonomous_cars =
      Enum.map(autonomous_cars, fn autonomous_car ->
        if autonomous_car.id === updated_autonomous_car_id do
          updated_autonomous_car
        else
          autonomous_car
        end
      end)

    %Race{race | autonomous_cars: updated_autonomous_cars}
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

  @spec record_crash_if_applicable(Race.t(), :left | :right | :front) :: Race.t()
  def record_crash_if_applicable(
        race = %Race{status: :ongoing, player_car: player_car},
        crash_check_side
      )
      when crash_check_side in [:left, :right, :front] do
    if CrashDetection.crash?(race, player_car, crash_check_side) do
      %Race{race | status: :crash}
    else
      race
    end
  end

  @spec end_if_applicable(Race.t()) :: Race.t()
  def end_if_applicable(race = %Race{status: :crash}) do
    race
  end

  def end_if_applicable(race = %Race{status: :ongoing}) do
    if player_car_past_finish?(race) do
      %Race{race | status: :ended}
    else
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
      autonomous_car.id === searched_autonomous_car_id
    end)
  end

  @spec new(map()) :: Race.t()
  def new(attrs) when is_map(attrs) do
    struct!(Race, attrs)
  end

  @spec remove_obstacles_in_the_vicinity_of_speedboosts(list(Obstacle.t()), list(SpeedBoost.t())) ::
          list(Obstacle.t())
  def remove_obstacles_in_the_vicinity_of_speedboosts(obstacles, speed_boosts)
      when is_list(obstacles) and is_list(speed_boosts) do
    obstacles
    |> Enum.reject(fn obstacle = %Obstacle{x_position: obstacle_x_position} ->
      Enum.any?(speed_boosts, fn speed_boost = %SpeedBoost{x_position: speed_boost_x_position} ->
        obstacle_x_position === speed_boost_x_position and
          obstacle_in_the_vicinity_of_speedboost?(obstacle, speed_boost)
      end)
    end)
  end

  @spec enable_speed_boost_if_fetched(Race.t()) :: Race.t()
  def enable_speed_boost_if_fetched(
        race = %Race{
          player_car: player_car = %Car{controller: :player, speed_boost_enabled?: false}
        }
      ) do
    if speed_boost_fetched?(race) do
      updated_player_car = Car.enable_speed_boost(player_car)

      Race.update_player_car(race, updated_player_car)
    else
      race
    end
  end

  # When the speed boost has been already activated and the car is still in the vicinity of speed boost
  def enable_speed_boost_if_fetched(
        race = %Race{
          player_car: %Car{controller: :player, speed_boost_enabled?: true}
        }
      ) do
    race
  end

  @doc """
  Adapts all autonomous cars correctly w.r.t player car position on screen
  """
  @spec adapt_autonomous_cars_positions(Race.t()) :: Race.t()
  def adapt_autonomous_cars_positions(race = %Race{autonomous_cars: autonomous_cars}) do
    adapt_autonomous_cars_positions(autonomous_cars, race)
  end

  @spec adapt_autonomous_cars_positions(list(Car.t()), Race.t()) :: Race.t()
  defp adapt_autonomous_cars_positions(
         [autonomous_car = %Car{controller: :autonomous}],
         race = %Race{}
       ) do
    updated_autonomous_car = Car.adapt_autonomous_car_position(autonomous_car, race)

    Race.update_autonomous_car(race, updated_autonomous_car)
  end

  defp adapt_autonomous_cars_positions(
         _autonomous_cars = [
           autonomous_car = %Car{controller: :autonomous} | remaining_autonomous_cars
         ],
         race = %Race{}
       ) do
    updated_autonomous_car = Car.adapt_autonomous_car_position(autonomous_car, race)
    updated_race = Race.update_autonomous_car(race, updated_autonomous_car)
    adapt_autonomous_cars_positions(remaining_autonomous_cars, updated_race)
  end

  @spec initialize_autonomous_cars(Car.t()) :: list(Car.t())
  defp initialize_autonomous_cars(%Car{
         id: player_car_id,
         image: player_car_image,
         controller: :player
       }) do
    available_ids = Car.get_all_possible_ids() -- [player_car_id]
    available_car_images = Utils.get_filenames_of_images!("cars") -- [player_car_image]

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

    [car | initialize_autonomous_cars(tail, remaining_car_images)]
  end

  @spec initialize_obstacles(Parameters.rem()) :: list(Obstacle.t())
  defp initialize_obstacles(race_distance) when is_float(race_distance) do
    %{distance: new_obstacle_distance} =
      new_obstacle = Obstacle.initialize_obstacle(@obstacle_or_speed_boost_prohibited_distance)

    [new_obstacle | initialize_obstacles(race_distance, new_obstacle_distance)]
  end

  @spec initialize_obstacles(Parameters.rem(), Parameters.rem()) :: list(Obstacle.t()) | []
  defp initialize_obstacles(race_distance, distance_covered_with_obstacles)
       when is_float(race_distance) and is_float(distance_covered_with_obstacles) do
    if race_distance - distance_covered_with_obstacles < @max_obstacle_y_position_step do
      []
    else
      %{distance: new_obstacle_distance} =
        new_obstacle = Obstacle.initialize_obstacle(distance_covered_with_obstacles)

      [new_obstacle | initialize_obstacles(race_distance, new_obstacle_distance)]
    end
  end

  @spec initialize_speed_boosts(Parameters.rem()) :: list(SpeedBoost.t())
  defp initialize_speed_boosts(race_distance) when is_float(race_distance) do
    %{distance: new_speed_boost_distance} =
      new_speed_boost =
      SpeedBoost.initialize_speed_boost(@obstacle_or_speed_boost_prohibited_distance)

    [new_speed_boost | initialize_speed_boosts(race_distance, new_speed_boost_distance)]
  end

  @spec initialize_speed_boosts(Parameters.rem(), Parameters.rem()) ::
          list(SpeedBoost.t()) | []
  defp initialize_speed_boosts(race_distance, distance_covered_with_speed_boosts)
       when is_float(race_distance) and is_float(distance_covered_with_speed_boosts) do
    if race_distance - distance_covered_with_speed_boosts < @speed_boost_y_position_step do
      []
    else
      %{distance: new_speed_boost_distance} =
        new_speed_boost = SpeedBoost.initialize_speed_boost(distance_covered_with_speed_boosts)

      [new_speed_boost | initialize_speed_boosts(race_distance, new_speed_boost_distance)]
    end
  end

  @spec player_car_past_finish?(Race.t()) :: boolean
  defp player_car_past_finish?(%Race{
         distance: race_distance,
         player_car: %Car{
           distance_travelled: distance_travelled_by_player_car,
           y_position: player_car_y_position,
           controller: :player
         }
       }) do
    # To check if the player car has travelled a distance of half the console screen height beyond the finish line.
    # This particular distance is just to make the end look smooth.
    distance_travelled_by_player_car + player_car_y_position >=
      race_distance + @console_screen_height / 2
  end

  @spec obstacle_in_the_vicinity_of_speedboost?(Obstacle.t(), SpeedBoost.t()) :: boolean()
  defp obstacle_in_the_vicinity_of_speedboost?(
         %Obstacle{distance: obstacle_distance},
         %SpeedBoost{distance: speed_boost_distance}
       ) do
    # Is obstacle in the area starting from '2 * @obstacle_or_speed_boost_length' behind speed boost
    # until ' 2 * @obstacle_or_speed_boost_length' after speed boost?
    obstacle_distance >= speed_boost_distance - 2 * @obstacle_or_speed_boost_length and
      obstacle_distance <= speed_boost_distance + 3 * @obstacle_or_speed_boost_length
  end

  @spec speed_boost_fetched?(Race.t()) :: boolean()
  defp speed_boost_fetched?(race = %Race{player_car: player_car}) do
    race
    |> get_same_lane_speed_boosts()
    |> Enum.any?(fn speed_boost -> overlaps_with_speed_boost?(player_car, speed_boost) end)
  end

  @spec get_same_lane_speed_boosts(Race.t()) :: list(SpeedBoost.t())
  defp get_same_lane_speed_boosts(race = %Race{player_car: player_car}) do
    player_car_lane = Car.get_lane(player_car)

    race
    |> get_lanes_and_speed_boosts_map()
    |> Map.get(player_car_lane, [])
  end

  @spec get_lanes_and_speed_boosts_map(Race.t()) :: map()
  defp get_lanes_and_speed_boosts_map(%Race{speed_boosts: speed_boosts}) do
    Enum.group_by(speed_boosts, &SpeedBoost.get_lane/1, & &1)
  end

  @spec overlaps_with_speed_boost?(Car.t(), SpeedBoost.t()) :: boolean()
  defp overlaps_with_speed_boost?(
         %Car{
           y_position: car_y_position,
           distance_travelled: distance_travelled_by_car,
           controller: :player
         },
         %SpeedBoost{distance: speed_boost_distance}
       ) do
    # Player car and the speed boost are exactly at the same position or
    # Player car front wheels are between speed boost rear and front or
    # Player car rear wheels are between speed boost rear and front
    (car_y_position + distance_travelled_by_car + @car_length >= speed_boost_distance and
       car_y_position + distance_travelled_by_car <= speed_boost_distance) or
      (car_y_position + distance_travelled_by_car <=
         speed_boost_distance + @obstacle_or_speed_boost_length and
         car_y_position + distance_travelled_by_car + @car_length >=
           speed_boost_distance + @obstacle_or_speed_boost_length)
  end
end
