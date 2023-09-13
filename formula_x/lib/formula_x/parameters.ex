defmodule FormulaX.Parameters do
  @moduledoc """
  All the racing game related parameters are defined here.
  TO DO: When it makes sense the important values defined in this module should be defined as environment variables
  """

  alias FormulaX.Race.Car

  @typedoc "Dimension on screen in X or Y direction measured in rem"
  @type rem() :: float()

  @spec console_screen_height() :: rem()
  def console_screen_height() do
    35.0
  end

  @doc """
  Total race distance
  """
  @spec race_distance() :: rem()
  def race_distance() do
    650.0
  end

  @spec background_image_container_height() :: rem()
  def background_image_container_height() do
    12.5
  end

  @doc """
  List of lane info maps.
  x_start and x_end are the limits of a lane along the X axis.
  Driving area is of 18rem width along X axis in total for 3 lanes with 6rem width per lane.
  """
  @spec lanes() :: list(map())
  def lanes() do
    [
      %{lane_number: 1, x_start: 0.0, x_end: 6.0},
      %{lane_number: 2, x_start: 6.0, x_end: 12.0},
      %{lane_number: 3, x_start: 12.0, x_end: 18.0}
    ]
  end

  @doc """
  Driving area limits map.
  x_start and x_end are the limits of the complete driving area along the X axis.
  """
  @spec driving_area_limits() :: map()
  def driving_area_limits() do
    x_start =
      lanes()
      |> Enum.find(fn lane -> lane.lane_number == 1 end)
      |> Map.fetch(:x_start)

    x_end =
      lanes()
      |> Enum.find(fn lane -> lane.lane_number == 3 end)
      |> Map.fetch(:x_end)

    %{x_start: x_start, x_end: x_end}
  end

  @doc """
  Car dimensions map
  """
  @spec car_dimensions() :: map()
  def car_dimensions() do
    car_width = 3.5
    %{width: car_width, length: car_width * 2}
  end

  @doc """
  List of car initial position coordinates.
  Origin point of cars is at the left bottom edge of first lane.
  """
  @spec car_initial_positions() :: list(Car.coordinates())
  def car_initial_positions() do
    [
      {1.25, 1.0},
      {7.25, 1.0},
      {13.25, 1.0},
      {1.25, 9.0},
      {7.25, 9.0},
      {13.25, 9.0}
    ]
  end

  @spec number_of_cars() :: integer()
  def number_of_cars() do
    car_initial_positions()
    |> Enum.count()
  end

  @spec car_drive_step(:rest | :low | :moderate | :high | :speed_boost) :: rem()
  def car_drive_step(_speed = :rest) do
    0.0
  end

  def car_drive_step(_speed = :low) do
    3.0
  end

  def car_drive_step(_speed = :moderate) do
    5.0
  end

  def car_drive_step(_speed = :high) do
    7.0
  end

  def car_drive_step(_speed = :speed_boost) do
    9.0
  end

  @spec car_steering_step() :: rem()
  def car_steering_step() do
    6.0
  end

  @doc """
  Stationary items (speed boosts, obstacles etc) dimensions map
  """
  @spec stationary_items_dimensions() :: map()
  def stationary_items_dimensions() do
    %{width: 6.0, length: 4.0}
  end

  @spec stationary_items_x_positions() :: list(rem())
  def stationary_items_x_positions() do
    [
      0.0,
      6.0,
      12.0
    ]
  end

  @doc """
  Obstacles are not placed until this distance after the start of race
  """
  @spec obstacle_free_distance() :: rem()
  def obstacle_free_distance() do
    60.0
  end

  @spec obstacle_y_position_steps() :: list(rem())
  def obstacle_y_position_steps() do
    [30.0, 60.0, 90.0]
  end

  @doc """
  Speed boosts are not placed until this distance after the start of race
  """
  @spec speed_boost_free_distance() :: rem()
  def speed_boost_free_distance() do
    60.0
  end

  @spec speed_boost_y_position_step() :: rem()
  def speed_boost_y_position_step() do
    300.0
  end
end
