defmodule FormulaX.Parameters do
  @moduledoc """
  Module to manage all parameters used in calculations done for Race visualisation
  """

  alias FormulaX.Race.Car

  @typedoc "Dimension on screen in X or Y direction measured in rem"
  @type rem() :: float()

  @spec get_parameters() :: map()
  def get_parameters() do
    Application.get_env(:formula_x, :parameters)
  end

  @spec race_distance() :: rem()
  def race_distance() do
    get_parameters()
    |> Map.get(:race_distance)
  end

  @spec lanes() :: list(map())
  def lanes() do
    get_parameters()
    |> Map.get(:lanes)
  end

  @spec driving_area_limits() :: map()
  def driving_area_limits() do
    x_start =
      lanes()
      |> Enum.find(fn lane -> lane.lane_number == 1 end)
      |> Map.get(:x_start)

    x_end =
      lanes()
      |> Enum.find(fn lane -> lane.lane_number == 3 end)
      |> Map.get(:x_end)

    %{x_start: x_start, x_end: x_end}
  end

  @spec car_length() :: rem()
  def car_length() do
    get_parameters()
    |> Map.get(:car_length)
  end

  @spec car_initial_positions() :: list(Car.coordinates())
  def car_initial_positions() do
    get_parameters()
    |> Map.get(:car_initial_positions)
  end

  @spec number_of_cars() :: integer()
  def number_of_cars() do
    car_initial_positions()
    |> Enum.count()
  end

  @spec car_drive_steps() :: map()
  defp car_drive_steps() do
    get_parameters()
    |> Map.get(:car_drive_steps)
  end

  @spec car_drive_step(:rest | :low | :moderate | :high | :speed_boost) :: rem()
  def car_drive_step(speed) do
    car_drive_steps()
    |> Map.get(speed)
  end

  @spec car_steering_step() :: rem()
  def car_steering_step() do
    get_parameters()
    |> Map.get(:car_steering_step)
  end

  @spec obstacles_and_speed_boosts_free_distance() :: rem()
  def obstacles_and_speed_boosts_free_distance() do
    get_parameters()
    |> Map.get(:obstacles_and_speed_boosts_free_distance)
  end

  @spec obstacles_and_speed_boosts_x_positions() :: list(rem())
  def obstacles_and_speed_boosts_x_positions() do
    lanes()
    |> Enum.map(fn lane_info -> lane_info.x_start end)
  end

  @spec obstacle_y_position_steps() :: list(rem())
  def obstacle_y_position_steps() do
    get_parameters()
    |> Map.get(:obstacle_y_position_steps)
  end

  @spec speed_boost_y_position_step() :: rem()
  def speed_boost_y_position_step() do
    get_parameters()
    |> Map.get(:speed_boost_y_position_step)
  end

  @spec console_screen_height() :: rem()
  def console_screen_height() do
    get_parameters()
    |> Map.get(:console_screen_height)
  end

  @spec background_image_height() :: rem()
  def background_image_height() do
    driving_area_width = driving_area_limits().x_end - driving_area_limits().x_start

    # Console screen has an aspect ratio of 1
    console_screen_width = console_screen_height()

    # Background images are displayed both both left and right sides of driving area
    # Background images too have an aspect ratio of 1 and so their height is same as their width
    (console_screen_width - driving_area_width) / 2
  end
end
