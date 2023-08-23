defmodule FormulaX.Race.Parameters do
  @moduledoc """
  All the racing game related parameters are defined here.
  !!! Keep all the values in this module as factors of 5 to be in sync with position_range_step() fn !!!
  TO DO: When it makes sense the values defined in this module should be defined as environment variables
  """

  alias FormulaX.Race
  alias FormulaX.Race.Car

  @typedoc """
  A value with pixels as the unit
  """
  @type pixel_value() :: integer()

  @spec console_screen_height() :: pixel_value()
  def console_screen_height() do
    560
  end

  @doc """
  List of lane info maps.
  x_start and x_end are the limits of a lane along the X axis in pixels.
  """
  @spec lanes() :: map()
  def lanes() do
    [
      %{lane_number: 1, x_start: 0, x_end: 60},
      %{lane_number: 2, x_start: 61, x_end: 160},
      %{lane_number: 3, x_start: 161, x_end: 230}
    ]
  end

  @doc """
  Total race distance.
  """
  @spec race_distance() :: Race.distance()
  def race_distance() do
    100_000
  end

  @doc """
  Driving area limits map.
  x_start and x_end are the limits of the complete driving area along the X axis in pixels.
  """
  @spec driving_area_limits() :: map()
  def driving_area_limits() do
    %{x_start: 0, x_end: 230}
  end

  @spec background_image_container_height() :: pixel_value()
  def background_image_container_height() do
    200
  end

  @doc """
  Car dimensions map in pixels.
  """
  @spec car_dimensions() :: map()
  def car_dimensions() do
    width = 55
    %{width: width, length: 2 * width}
  end

  @doc """
  List of car initial position coordinates.
  Origin point of cars is at the left bottom edge of first lane.
  """
  @spec car_initial_positions() :: list(Car.coordinates())
  def car_initial_positions() do
    [{20, 0}, {20, 115}, {115, 0}, {115, 115}, {210, 0}, {210, 115}]
  end

  @spec number_of_cars() :: integer()
  def number_of_cars() do
    car_initial_positions()
    |> Enum.count()
  end

  @spec car_forward_movement_step(:rest | :low | :moderate | :high) :: pixel_value()
  def car_forward_movement_step(_speed = :rest) do
    0
  end

  def car_forward_movement_step(_speed = :low) do
    50
  end

  def car_forward_movement_step(_speed = :moderate) do
    75
  end

  def car_forward_movement_step(_speed = :high) do
    100
  end

  @spec car_sideward_movement_step() :: pixel_value()
  def car_sideward_movement_step() do
    5
  end

  @doc """
  This is the step value used to create x and y position ranges used in Crash Detection module.
  It is set to a value of 5 because the car border coordinates those will result after any kind of car movement have been ensured to be as factors of 5.
  So the number of coordinates that will be used in crash checks will not be too many.
  """
  @spec position_range_step() :: pixel_value()
  def position_range_step() do
    5
  end
end
