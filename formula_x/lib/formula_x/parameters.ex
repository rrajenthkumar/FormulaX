defmodule FormulaX.Parameters do
  @moduledoc """
  All the racing game related parameters are defined here.
  TO DO: When it makes sense the important values defined in this module should be defined as environment variables or read from a yaml file
  """

  alias FormulaX.Race.Car

  @typedoc "Dimension on screen in X or Y direction measured in pixels"
  @type pixel() :: integer()

  @spec console_screen_height() :: pixel()
  def console_screen_height() do
    560
  end

  @doc """
  List of lane info maps.
  x_start and x_end are the limits of a lane along the X axis.
  """
  @spec lanes() :: list(map())
  def lanes() do
    [
      %{lane_number: 1, x_start: 0, x_end: 60},
      %{lane_number: 2, x_start: 61, x_end: 160},
      %{lane_number: 3, x_start: 161, x_end: 230}
    ]
  end

  @doc """
  Total race distance
  """
  @spec race_distance() :: pixel()
  def race_distance() do
    10000
  end

  @doc """
  Driving area limits map.
  x_start and x_end are the limits of the complete driving area along the X axis.
  """
  @spec driving_area_limits() :: map()
  def driving_area_limits() do
    %{x_start: 0, x_end: 230}
  end

  @spec background_image_container_height() :: pixel()
  def background_image_container_height() do
    200
  end

  @doc """
  Car dimensions map
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
    [
      {20, 5},
      {115, 5},
      {210, 5},
      {20, 120},
      {115, 120},
      {210, 120}
      # ,
      # {20, 235},
      # {115, 235},
      # {210, 235}
    ]
  end

  @spec number_of_cars() :: integer()
  def number_of_cars() do
    car_initial_positions()
    |> Enum.count()
  end

  @spec car_drive_step(:rest | :low | :moderate | :high) :: pixel()
  def car_drive_step(_speed = :rest) do
    0
  end

  def car_drive_step(_speed = :low) do
    50
  end

  def car_drive_step(_speed = :moderate) do
    75
  end

  def car_drive_step(_speed = :high) do
    100
  end

  def car_drive_step(_speed = :speed_boost) do
    125
  end

  @spec car_steering_step() :: pixel()
  def car_steering_step() do
    95
  end

  @doc """
  Obstacles are not placed until this distance after the start of race
  """
  @spec obstacle_free_distance() :: pixel()
  def obstacle_free_distance() do
    1000
  end

  @spec obstacle_y_position_steps() :: list(pixel())
  def obstacle_y_position_steps() do
    [500, 1000, 1500]
  end

  @spec obstacle_x_positions() :: list(pixel())
  def obstacle_x_positions() do
    [
      0,
      95,
      190
    ]
  end

  @doc """
  Speed boosts are not placed until this distance after the start of race
  """
  @spec speed_boost_free_distance() :: pixel()
  def speed_boost_free_distance() do
    1000
  end

  @spec speed_boost_y_position_step() :: pixel()
  def speed_boost_y_position_step() do
    5000
  end

  @spec speed_boost_x_positions() :: list(pixel())
  def speed_boost_x_positions() do
    [
      0,
      95,
      190
    ]
  end

  @doc """
  Obstacle dimensions map
  """
  @spec obstacle_dimensions() :: map()
  def obstacle_dimensions() do
    %{width: 96, length: 64}
  end

  @spec speed_boost_dimensions() :: map()
  def speed_boost_dimensions() do
    %{width: 96, length: 48}
  end
end
