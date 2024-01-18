defmodule FormulaX.Race.Obstacle do
  @moduledoc """
  The Obstacle context
  Obstacles (multiple heaps of tires) to be avoided are placed randomly on lanes.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @typedoc "Obstacle struct"
  typedstruct do
    field(:x_position, Parameters.rem(), enforce: true)
    field(:distance, Parameters.rem(), enforce: true)
  end

  @spec initialize_obstacle(Parameters.rem()) :: Obstacle.t()
  def initialize_obstacle(distance_covered_with_obstacles)
      when is_float(distance_covered_with_obstacles) do
    obstacle_x_position =
      Parameters.obstacles_and_speed_boosts_x_positions()
      |> Enum.random()

    obstacle_y_position_step =
      Parameters.obstacle_y_position_steps()
      |> Enum.random()

    new(%{
      x_position: obstacle_x_position,
      distance: distance_covered_with_obstacles + obstacle_y_position_step
    })
  end

  @spec get_y_position(Obstacle.t(), Race.t()) :: Parameters.rem()
  def get_y_position(
        %Obstacle{distance: obstacle_distance},
        %Race{
          player_car: %Car{
            distance_travelled: distance_travelled_by_player_car,
            y_position: player_car_y_position,
            controller: :player
          }
        }
      ) do
    obstacle_distance - (distance_travelled_by_player_car + player_car_y_position)
  end

  @spec get_lane(Obstacle.t()) :: integer()
  def get_lane(%Obstacle{x_position: obstacle_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      obstacle_x_position >= lane_x_start and obstacle_x_position < lane_x_end
    end)
    |> Map.get(:lane_number)
  end

  @spec new(map()) :: Obstacle.t()
  defp new(attrs) when is_map(attrs) do
    struct!(Obstacle, attrs)
  end
end
