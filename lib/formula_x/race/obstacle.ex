defmodule FormulaX.Race.Obstacle do
  @moduledoc """
  The Obstacle context
  Obstacles (multiple heaps of tires) to be avoided are placed randomly on lanes.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters

  @typedoc "Obstacle struct"
  typedstruct do
    field(:x_position, Parameters.rem(), enforce: true)
    field(:distance, Parameters.rem(), enforce: true)
  end

  @doc """
  The newly initiated obstacle will be placed only beyond 'obstacles_prohibited_distance_or_distance_already_covered_with_obstacles' part of the track.
  """
  @spec initialize_obstacle(Parameters.rem()) :: Obstacle.t()
  def initialize_obstacle(
        obstacles_prohibited_distance_or_distance_already_covered_with_obstacles
      )
      when is_float(obstacles_prohibited_distance_or_distance_already_covered_with_obstacles) do
    obstacle_x_position =
      Parameters.obstacles_and_speed_boosts_x_positions()
      |> Enum.random()

    obstacle_y_position_step =
      Parameters.obstacle_y_position_steps()
      |> Enum.random()

    new(%{
      x_position: obstacle_x_position,
      distance:
        obstacles_prohibited_distance_or_distance_already_covered_with_obstacles +
          obstacle_y_position_step
    })
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
  def new(attrs) when is_map(attrs) do
    struct!(Obstacle, attrs)
  end
end
