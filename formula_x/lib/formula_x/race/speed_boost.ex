defmodule FormulaX.Race.SpeedBoost do
  @moduledoc """
  **SpeedBoost**
  Few special items known as 'speed boosts' are placed randomly on tracks to help player car drive super fast for few seconds.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @speed_boost_free_distance Parameters.speed_boost_free_distance()
  @speed_boost_y_position_step Parameters.speed_boost_y_position_step()
  @speed_boost_length Parameters.stationary_items_length()
  @car_length Parameters.car_length()

  @typedoc "SpeedBoost struct"
  typedstruct do
    field(:x_position, Parameters.rem(), enforce: true)
    field(:distance, Parameters.rem(), enforce: true)
  end

  @spec new(map()) :: SpeedBoost.t()
  defp new(attrs) when is_map(attrs) do
    struct!(SpeedBoost, attrs)
  end

  @spec initialize_speed_boosts(Parameters.rem()) :: list(SpeedBoost.t())
  def initialize_speed_boosts(race_distance) when is_float(race_distance) do
    %{distance: new_speed_boost_distance} =
      new_speed_boost = initialize_speed_boost(@speed_boost_free_distance)

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
          new_speed_boost = initialize_speed_boost(distance_covered_with_speed_boosts)

        [new_speed_boost] ++
          initialize_speed_boosts(race_distance, new_speed_boost_distance)
    end
  end

  @spec initialize_speed_boost(Parameters.rem()) :: SpeedBoost.t()
  defp initialize_speed_boost(distance_covered_with_speed_boosts)
       when is_float(distance_covered_with_speed_boosts) do
    speed_boost_x_position =
      Parameters.stationary_items_x_positions()
      |> Enum.random()

    new(%{
      x_position: speed_boost_x_position,
      distance: distance_covered_with_speed_boosts + @speed_boost_y_position_step
    })
  end

  @spec get_lane(SpeedBoost.t()) :: integer()
  def get_lane(%SpeedBoost{x_position: speed_boost_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      speed_boost_x_position >= lane_x_start and speed_boost_x_position < lane_x_end
    end)
    |> Map.fetch!(:lane_number)
  end

  @spec get_y_position(SpeedBoost.t(), Race.t()) :: Parameters.rem()
  def get_y_position(
        %SpeedBoost{distance: speed_boost_distance},
        %Race{
          player_car: %Car{
            distance_travelled: distance_travelled_by_player_car,
            controller: :player
          }
        }
      ) do
    speed_boost_distance - distance_travelled_by_player_car
  end

  @spec enable_if_fetched(Race.t()) :: Race.t()
  def enable_if_fetched(race = %Race{player_car: player_car = %Car{controller: :player}}) do
    case speed_boost_fetched?(race) do
      true ->
        updated_player_car = Car.enable_speed_boost(player_car)
        Race.update_player_car(race, updated_player_car)

      false ->
        race
    end
  end

  @spec speed_boost_fetched?(Race.t()) :: boolean()
  defp speed_boost_fetched?(
         race = %Race{
           player_car: player_car = %Car{controller: :player, y_position: player_car_y_position}
         }
       ) do
    race
    |> get_same_lane_speed_boosts(player_car)
    |> Enum.any?(fn speed_boost ->
      speed_boost_y_position = get_y_position(speed_boost, race)

      # Player car front wheels between speed boost starting and ending y positions or
      # Player car rear wheels between speed boost starting and ending y positions
      (player_car_y_position + @car_length >= speed_boost_y_position and
         player_car_y_position <= speed_boost_y_position) or
        (player_car_y_position >= speed_boost_y_position and
           player_car_y_position <=
             speed_boost_y_position + @speed_boost_length)
    end)
  end

  @spec get_same_lane_speed_boosts(Race.t(), Car.t()) :: list(SpeedBoost.t())
  defp get_same_lane_speed_boosts(
         race = %Race{},
         player_car = %Car{controller: :player}
       ) do
    player_car_lane = Car.get_lane(player_car)

    race
    |> Race.get_lanes_and_speed_boosts_map()
    |> Map.get(player_car_lane, [])
  end
end
