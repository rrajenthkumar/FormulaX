defmodule FormulaX.Race.Background do
  @moduledoc """
  The Background context
  Background struct is used by Race struct to display and move background images on both the left and right sides of racing lanes based on player car movement.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Parameters
  alias FormulaX.Utils

  @console_screen_height Parameters.console_screen_height()
  @background_image_height Parameters.background_image_height()

  @type filename :: String.t()
  @type filenames :: list(filename())

  @typedoc "Background struct"
  typedstruct do
    field(:left_side_images, filenames(), enforce: true)
    field(:right_side_images, filenames(), enforce: true)
    field(:y_position, Parameters.rem(), enforce: true)
  end

  @spec initialize(Parameters.rem()) :: Background.t()
  def initialize(race_distance) when is_float(race_distance) do
    available_background_images = Utils.get_filenames_of_images!("backgrounds")
    left_side_images = get_side_images(available_background_images, race_distance)
    right_side_images = get_side_images(available_background_images, race_distance)

    # The origins of left and right side Background DIVs which are at their top left edges
    # are initially aligned to the top of console screen.
    # After the below correction the bottom of these Background DIVs
    # will be at a distance of '@console_screen_height' beyond the top of console screen.
    # This is done to ensure that we can add few more background images
    # to the bottom of the DIVs to show after the finish line.
    y_position = -@console_screen_height - race_distance

    new(%{
      left_side_images: left_side_images,
      right_side_images: right_side_images,
      y_position: y_position
    })
  end

  @spec move(Background.t(), :rest | :low | :moderate | :high | :speed_boost) :: Background.t()
  def move(background = %Background{y_position: y_position}, player_car_speed)
      when player_car_speed in [:rest, :low, :moderate, :high, :speed_boost] do
    car_drive_step = Parameters.car_drive_step(player_car_speed)
    updated_y_position = y_position + car_drive_step

    %Background{background | y_position: updated_y_position}
  end

  @spec new(map()) :: Background.t()
  def new(attrs) when is_map(attrs) do
    struct!(Background, attrs)
  end

  @spec get_side_images(filenames(), Parameters.rem()) :: filenames()
  defp get_side_images(available_background_images, race_distance)
       when is_float(race_distance) and is_list(available_background_images) do
    # 2 * @console_screen_height is added to race length here to have few more background images
    # to be shown after the finish line as explained earlier

    number_of_images_required =
      ((race_distance + 2 * @console_screen_height) /
         @background_image_height)
      |> round()

    Enum.map(1..number_of_images_required, fn _grid_number ->
      Enum.random(available_background_images)
    end)
  end
end
