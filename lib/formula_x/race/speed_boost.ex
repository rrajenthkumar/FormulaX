defmodule FormulaX.Race.SpeedBoost do
  @moduledoc """
  The Speed boost context
  Speed boost items are placed randomly on tracks to help 'player car' drive faster than usual for '5' seconds.
  A speed boost gets activated when the player car drives past it on it's lane.
  A speed boosted car is highlighted in red colour rather than the usual blue.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @speed_boost_y_position_step Parameters.speed_boost_y_position_step()

  @typedoc "SpeedBoost struct"
  typedstruct do
    field(:x_position, Parameters.rem(), enforce: true)
    field(:distance, Parameters.rem(), enforce: true)
  end

  @doc """
  The newly initiated speed boost will be placed only beyond 'speed_boost_prohibited_distance_or_distance_already_covered_with_speed_boosts' part of the track.
  """
  @spec initialize_speed_boost(Parameters.rem()) :: SpeedBoost.t()
  def initialize_speed_boost(
        speed_boost_prohibited_distance_or_distance_already_covered_with_speed_boosts
      )
      when is_float(speed_boost_prohibited_distance_or_distance_already_covered_with_speed_boosts) do
    speed_boost_x_position =
      Parameters.obstacles_and_speed_boosts_x_positions()
      |> Enum.random()

    new(%{
      x_position: speed_boost_x_position,
      distance:
        speed_boost_prohibited_distance_or_distance_already_covered_with_speed_boosts +
          @speed_boost_y_position_step
    })
  end

  @spec get_y_position(SpeedBoost.t(), Race.t()) :: Parameters.rem()
  def get_y_position(
        %SpeedBoost{distance: speed_boost_distance},
        %Race{
          player_car: %Car{
            distance_travelled: distance_travelled_by_player_car,
            y_position: player_car_y_position,
            controller: :player
          }
        }
      ) do
    speed_boost_distance - (distance_travelled_by_player_car + player_car_y_position)
  end

  @spec get_lane(SpeedBoost.t()) :: integer()
  def get_lane(%SpeedBoost{x_position: speed_boost_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      speed_boost_x_position >= lane_x_start and speed_boost_x_position < lane_x_end
    end)
    |> Map.get(:lane_number)
  end

  @spec new(map()) :: SpeedBoost.t()
  def new(attrs) when is_map(attrs) do
    struct!(SpeedBoost, attrs)
  end
end
