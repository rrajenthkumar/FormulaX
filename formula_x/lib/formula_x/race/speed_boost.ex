defmodule FormulaX.Race.SpeedBoost do
  @moduledoc """
  The Speed boost context
  Speed boost items are placed rarely, randomly on tracks to help player car drive faster than usual for few seconds. It gets activated when the player car drives past a Speed boost on it's lane.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @speed_boost_y_position_step Parameters.speed_boost_y_position_step()
  # Speed boost elements have been set to the same length as cars
  @speed_boost_length Parameters.car_length()
  @car_length Parameters.car_length()

  @typedoc "SpeedBoost struct"
  typedstruct do
    field(:x_position, Parameters.rem(), enforce: true)
    field(:distance, Parameters.rem(), enforce: true)
  end

  @spec initialize_speed_boost(Parameters.rem()) :: SpeedBoost.t()
  def initialize_speed_boost(distance_covered_with_speed_boosts)
      when is_float(distance_covered_with_speed_boosts) do
    speed_boost_x_position =
      Parameters.obstacles_and_speed_boosts_x_positions()
      |> Enum.random()

    new(%{
      x_position: speed_boost_x_position,
      distance: distance_covered_with_speed_boosts + @speed_boost_y_position_step
    })
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

  @spec get_lane(SpeedBoost.t()) :: integer()
  def get_lane(%SpeedBoost{x_position: speed_boost_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      speed_boost_x_position >= lane_x_start and speed_boost_x_position < lane_x_end
    end)
    |> Map.get(:lane_number)
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

  @spec new(map()) :: SpeedBoost.t()
  defp new(attrs) when is_map(attrs) do
    struct!(SpeedBoost, attrs)
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
    |> get_lanes_and_speed_boosts_map()
    |> Map.get(player_car_lane, [])
  end

  @spec get_lanes_and_speed_boosts_map(Race.t()) :: map()
  defp get_lanes_and_speed_boosts_map(%Race{speed_boosts: speed_boosts}) do
    Enum.group_by(speed_boosts, &SpeedBoost.get_lane/1, & &1)
  end
end
