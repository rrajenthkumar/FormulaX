defmodule FormulaX.Race.SpeedBoost do
  @moduledoc """
  **SpeedBoost**
  Few speed boosts are placed randomly on tracks to help player car drive super fast for few seconds.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @typedoc "SpeedBoost struct"
  typedstruct do
    field(:x_position, Parameters.pixel(), enforce: true)
    field(:distance, Parameters.pixel(), enforce: true)
  end

  @spec new(map()) :: SpeedBoost.t()
  defp new(attrs) when is_map(attrs) do
    struct!(SpeedBoost, attrs)
  end

  @spec initialize_speed_boosts(Parameters.pixel()) :: list(SpeedBoost.t())
  def initialize_speed_boosts(race_distance) when is_integer(race_distance) do
    %{distance: new_speed_boost_distance} =
      new_speed_boost = initialize_speed_boost(Parameters.speed_boost_free_distance())

    [new_speed_boost] ++
      initialize_speed_boosts(race_distance, new_speed_boost_distance)
  end

  @spec initialize_speed_boosts(Parameters.pixel(), Parameters.pixel()) ::
          list(SpeedBoost.t()) | []
  defp initialize_speed_boosts(race_distance, distance_covered_with_speed_boosts)
       when is_integer(race_distance) and is_integer(distance_covered_with_speed_boosts) do
    cond do
      race_distance - distance_covered_with_speed_boosts <
          Parameters.speed_boost_y_position_step() ->
        []

      true ->
        %{distance: new_speed_boost_distance} =
          new_speed_boost = initialize_speed_boost(distance_covered_with_speed_boosts)

        [new_speed_boost] ++
          initialize_speed_boosts(race_distance, new_speed_boost_distance)
    end
  end

  @spec initialize_speed_boost(Parameters.pixel()) :: SpeedBoost.t()
  defp initialize_speed_boost(distance_covered_with_speed_boosts)
       when is_integer(distance_covered_with_speed_boosts) do
    speed_boost_x_position =
      Parameters.speed_boost_x_positions()
      |> Enum.random()

    new(%{
      x_position: speed_boost_x_position,
      distance: distance_covered_with_speed_boosts + Parameters.speed_boost_y_position_step()
    })
  end

  @spec get_lane(SpeedBoost.t()) :: integer()
  def get_lane(%SpeedBoost{x_position: speed_boost_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      speed_boost_x_position in lane_x_start..lane_x_end
    end)
    |> Map.fetch!(:lane_number)
  end

  @spec get_y_position(SpeedBoost.t(), Race.t()) :: Parameters.pixel()
  def get_y_position(%SpeedBoost{distance: speed_boost_distance}, race = %Race{}) do
    %Car{distance_travelled: distance_travelled_by_player_car} = Race.get_player_car(race)
    speed_boost_distance - distance_travelled_by_player_car
  end
end
