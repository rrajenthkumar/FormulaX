defmodule FormulaX.Race.Obstacle do
  @moduledoc """
  **Obstacle context**
  Obstacles (heaps of tires) to be avoided are placed randomly on lanes.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @typedoc "Obstacle struct"
  typedstruct do
    field(:x_position, Parameters.pixel(), enforce: true)
    field(:distance, Parameters.pixel(), enforce: true)
  end

  @spec new(map()) :: Obstacle.t()
  defp new(attrs) when is_map(attrs) do
    struct!(Obstacle, attrs)
  end

  @spec initialize_obstacles(Parameters.pixel()) :: list(Obstacle.t())
  def initialize_obstacles(race_distance) when is_integer(race_distance) do
    %{distance: new_obstacle_distance} =
      new_obstacle = initialize_obstacle(Parameters.obstacle_free_distance())

    [new_obstacle] ++
      initialize_obstacles(race_distance, new_obstacle_distance)
  end

  @spec initialize_obstacles(Parameters.pixel(), Parameters.pixel()) :: list(Obstacle.t()) | []
  defp initialize_obstacles(race_distance, distance_covered_with_obstacles)
       when is_integer(race_distance) and is_integer(distance_covered_with_obstacles) do
    cond do
      race_distance - distance_covered_with_obstacles <
          max_obstacle_y_position_step() ->
        []

      true ->
        %{distance: new_obstacle_distance} =
          new_obstacle = initialize_obstacle(distance_covered_with_obstacles)

        [new_obstacle] ++
          initialize_obstacles(race_distance, new_obstacle_distance)
    end
  end

  @spec initialize_obstacle(Parameters.pixel()) :: Obstacle.t()
  defp initialize_obstacle(distance_covered_with_obstacles)
       when is_integer(distance_covered_with_obstacles) do
    obstacle_x_position =
      Parameters.obstacle_x_positions()
      |> Enum.random()

    obstacle_y_position_step =
      Parameters.obstacle_y_position_steps()
      |> Enum.random()

    new(%{
      x_position: obstacle_x_position,
      distance: distance_covered_with_obstacles + obstacle_y_position_step
    })
  end

  @spec max_obstacle_y_position_step() :: Parameters.pixel()
  defp max_obstacle_y_position_step() do
    Parameters.obstacle_y_position_steps()
    |> Enum.max()
  end

  @spec get_lane(Obstacle.t()) :: integer()
  def get_lane(%Obstacle{x_position: obstacle_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      obstacle_x_position in lane_x_start..lane_x_end
    end)
    |> Map.fetch!(:lane_number)
  end

  @spec get_obstacle_y_position(Obstacle.t(), Race.t()) :: Parameters.pixel()
  def get_obstacle_y_position(%Obstacle{distance: obstacle_distance}, race = %Race{}) do
    %Car{distance_travelled: distance_travelled_by_player_car} = Race.get_player_car(race)
    obstacle_distance - distance_travelled_by_player_car
  end
end
