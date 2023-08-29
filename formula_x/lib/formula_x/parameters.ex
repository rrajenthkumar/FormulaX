defmodule FormulaX.Parameters do
  @moduledoc """
  All the racing game related parameters are defined here.
  TO DO: When it makes sense the important values defined in this module should be defined as environment variables or read from a yaml file
  """

  alias FormulaX.Race.Car

  @typedoc "Dimension on screen in X or Y direction measured in pixels"
  @type pixel() :: integer()

  @doc """
  To have all parameter values as factors of 5 and to keep them relative to eachother, a single unit is set as 5px.
  """
  @spec unit :: pixel()
  def unit do
    5
  end

  @spec console_screen_height() :: pixel()
  def console_screen_height() do
    112 * unit()
  end

  @doc """
  List of lane info maps.
  x_start and x_end are the limits of a lane along the X axis.
  """
  @spec lanes() :: list(map())
  def lanes() do
    [
      %{lane_number: 1, x_start: 0, x_end: 12 * unit()},
      %{lane_number: 2, x_start: 12 * unit() + 1, x_end: 32 * unit()},
      %{lane_number: 3, x_start: 32 * unit() + 1, x_end: 46 * unit()}
    ]
  end

  @doc """
  Total race distance
  """
  @spec race_distance() :: pixel()
  def race_distance() do
    500 * unit()
  end

  @doc """
  Driving area limits map.
  x_start and x_end are the limits of the complete driving area along the X axis.
  """
  @spec driving_area_limits() :: map()
  def driving_area_limits() do
    %{x_start: 0, x_end: 46 * unit()}
  end

  @spec background_image_container_height() :: pixel()
  def background_image_container_height() do
    40 * unit()
  end

  @doc """
  Car dimensions map
  """
  @spec car_dimensions() :: map()
  def car_dimensions() do
    width = 11 * unit()
    %{width: width, length: 2 * width}
  end

  @doc """
  List of car initial position coordinates.
  Origin point of cars is at the left bottom edge of first lane.
  """
  @spec car_initial_positions() :: list(Car.coordinates())
  def car_initial_positions() do
    [
      {4 * unit(), 1 * unit()},
      {4 * unit(), 24 * unit()},
      {23 * unit(), 1 * unit()},
      {23 * unit(), 24 * unit()},
      {42 * unit(), 1 * unit()},
      {42 * unit(), 24 * unit()},
      {4 * unit(), 47 * unit()},
      {23 * unit(), 47 * unit()},
      {42 * unit(), 47 * unit()}
    ]
  end

  @spec number_of_cars() :: integer()
  def number_of_cars() do
    car_initial_positions()
    |> Enum.count()
  end

  @spec car_forward_movement_step(:rest | :low | :moderate | :high) :: pixel()
  def car_forward_movement_step(_speed = :rest) do
    0
  end

  def car_forward_movement_step(_speed = :low) do
    10 * unit()
  end

  def car_forward_movement_step(_speed = :moderate) do
    15 * unit()
  end

  def car_forward_movement_step(_speed = :high) do
    20 * unit()
  end

  @spec car_sideward_movement_step() :: pixel()
  def car_sideward_movement_step() do
    1 * unit()
  end

  @doc """
  This is the step value used to create x and y position ranges in Crash Detection module.
  It is set to a value of 1 * unit() so that the number of coordinates that will be used in crash checks will not be too many.
  """
  @spec position_range_step() :: pixel()
  def position_range_step() do
    1 * unit()
  end
end
