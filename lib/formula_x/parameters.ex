defmodule FormulaX.Parameters do
  @moduledoc """
  To centralise extraction of different race parameters used in calculations from config file.
  """

  alias FormulaX.Race.Car

  @typedoc "Dimension on screen in X or Y direction measured in rem"
  @type rem() :: float()

  @spec race_distance() :: rem()
  def race_distance do
    get_parameters()
    |> Map.get(:race_distance)
  end

  @doc """
  Returns a lane info map with limits of lanes in x direction
  """
  @spec lanes() :: list(map())
  def lanes do
    get_parameters()
    |> Map.get(:lanes)
  end

  @spec driving_area_limits() :: map()
  def driving_area_limits do
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
  def car_length do
    get_parameters()
    |> Map.get(:car_length)
  end

  @spec car_initial_positions() :: list(Car.coordinates())
  def car_initial_positions do
    get_parameters()
    |> Map.get(:car_initial_positions)
  end

  @spec number_of_cars() :: integer()
  def number_of_cars do
    car_initial_positions()
    |> Enum.count()
  end

  @doc """
  Forward movement distance for cars during each call of the drive() function
  """
  @spec car_drive_step(:rest | :low | :moderate | :high | :speed_boost) :: rem()
  def car_drive_step(speed) when speed in [:rest, :low, :moderate, :high, :speed_boost] do
    car_drive_steps()
    |> Map.get(speed)
  end

  @doc """
  Sideward movement distance for cars when steer() function is called
  """
  @spec car_steering_step() :: rem()
  def car_steering_step do
    get_parameters()
    |> Map.get(:car_steering_step)
  end

  @spec obstacle_and_speed_boost_length() :: rem()
  def obstacle_and_speed_boost_length do
    get_parameters()
    |> Map.get(:obstacle_and_speed_boost_length)
  end

  @doc """
  Used to set obstacles and speed boosts free distance to avoid seeing obstacles and speedboost as soon as the race begins
  """
  @spec obstacles_and_speed_boosts_prohibited_distance() :: rem()
  def obstacles_and_speed_boosts_prohibited_distance do
    get_parameters()
    |> Map.get(:obstacles_and_speed_boosts_prohibited_distance)
  end

  @spec obstacles_and_speed_boosts_x_positions() :: list(rem())
  def obstacles_and_speed_boosts_x_positions do
    lanes()
    |> Enum.map(fn lane_info -> lane_info.x_start end)
  end

  @doc """
  Returns a list of possible step values for positioning the next obstacle after an already positioned obstacle or after the obstacles free distance
  """
  @spec obstacle_y_position_steps() :: list(rem())
  def obstacle_y_position_steps do
    get_parameters()
    |> Map.get(:obstacle_y_position_steps)
  end

  @spec max_obstacle_y_position_step() :: rem()
  def max_obstacle_y_position_step do
    obstacle_y_position_steps()
    |> Enum.max()
  end

  @doc """
  Returns the step value for positioning the next speed boost after an already positioned speed boost or after the speed boosts free distance
  """
  @spec speed_boost_y_position_step() :: rem()
  def speed_boost_y_position_step do
    get_parameters()
    |> Map.get(:speed_boost_y_position_step)
  end

  @spec console_screen_height() :: rem()
  def console_screen_height do
    get_parameters()
    |> Map.get(:console_screen_height)
  end

  @spec background_image_height() :: rem()
  def background_image_height do
    driving_area_width = driving_area_limits().x_end - driving_area_limits().x_start

    # Console screen has an aspect ratio of 1
    console_screen_width = console_screen_height()

    # Background images are displayed both both left and right sides of driving area
    # Background images too have an aspect ratio of 1 and so their height is same as their width
    (console_screen_width - driving_area_width) / 2
  end

  @spec get_parameters() :: map()
  defp get_parameters do
    Application.get_env(:formula_x, :parameters)
  end

  @spec car_drive_steps() :: map()
  defp car_drive_steps do
    get_parameters()
    |> Map.get(:car_drive_steps)
  end
end
