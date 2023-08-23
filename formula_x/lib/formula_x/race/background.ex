defmodule FormulaX.Race.Background do
  @moduledoc """
  **Race background context**
  Background struct is used to display background images on both the left and right sides of racing lanes.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Utils
  alias FormulaX.Race.Parameters

  @type filename :: String.t()
  @type filenames :: list(filename())
  @type y_position :: integer()

  @typedoc "Background struct"
  typedstruct do
    field(:left_side_images, filenames(), enforce: true)
    field(:right_side_images, filenames(), enforce: true)
    field(:y_position, y_position(), enforce: true)
  end

  @spec new(map()) :: Background.t()
  def new(attrs) when is_map(attrs) do
    struct!(Background, attrs)
  end

  @spec initialize(Race.distance()) :: Background.t()
  def initialize(race_distance) when is_integer(race_distance) do
    available_background_images = Utils.get_images("backgrounds")
    left_side_images = get_side_images(available_background_images, race_distance)
    right_side_images = get_side_images(available_background_images, race_distance)

    # In the beginning, background DIVs are positioned in Y direction, w.r.t the top of console screen.
    # The following is done to position them in Y direction with the same reference as that of cars (bottom of console screen)
    console_screen_height = Parameters.console_screen_height()
    y_position = console_screen_height - race_distance

    new(%{
      left_side_images: left_side_images,
      right_side_images: right_side_images,
      y_position: y_position
    })
  end

  @spec move(Background.t(), :rest | :low | :moderate | :high) :: Background.t()
  def move(background = %Background{y_position: y_position}, player_car_speed)
      when is_atom(player_car_speed) do
    car_forward_movement_step = Parameters.car_forward_movement_step(player_car_speed)
    updated_y_position = y_position + car_forward_movement_step

    %Background{background | y_position: updated_y_position}
  end

  @spec get_side_images(filenames(), Race.distance()) :: filenames()
  defp get_side_images(available_background_images, race_distance)
       when is_integer(race_distance) and is_list(available_background_images) do
    image_container_height = Parameters.background_image_container_height()
    number_of_images_required = div(race_distance, image_container_height)

    Enum.map(1..number_of_images_required, fn _grid_number ->
      Enum.random(available_background_images)
    end)
  end
end
