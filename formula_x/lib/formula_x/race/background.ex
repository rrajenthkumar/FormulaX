defmodule FormulaX.Race.Background do
  @moduledoc """
  Background context
  Background images are shown on both left and right sides.
  Images can be of a tree, a rock, a building etc.
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Utils

  @type filename :: String.t()
  @type filenames :: list(filename())
  @typedoc "Position on screen in pixels to which the background has to be moved in opposite Y (reverse) direction, so that the player car appears to move forward along Y direction"
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
    left_side_images = get_side_images(race_distance, available_background_images)
    right_side_images = get_side_images(race_distance, available_background_images)

    # The origin of background div is at Top left corner of screen is .
    # To bring the bottom of the background strips on both sides
    # to the origin point of cars (bottom left corner of left racing lane)
    # This has to be avoided by correcting css if possible!!!
    y_position = -race_distance + 560
    # 560px is the console screen height

    new(%{
      left_side_images: left_side_images,
      right_side_images: right_side_images,
      y_position: y_position
    })
  end

  @spec get_side_images(Race.distance(), filenames()) :: filenames()
  defp get_side_images(race_distance, available_background_images)
       when is_integer(race_distance) and is_list(available_background_images) do
    # 200px is the width of one background image container in Y direction
    number_of_images_required = div(race_distance, 200)

    Enum.map(1..number_of_images_required, fn _grid_number ->
      Enum.random(available_background_images)
    end)
  end

  @spec move(Background.t(), :rest | :low | :moderate | :high) :: Background.t()
  def move(background = %Background{y_position: y_position}, player_car_speed)
      when is_atom(player_car_speed) do
    case player_car_speed do
      :rest -> background
      :low -> %Background{background | y_position: y_position + 50}
      :moderate -> %Background{background | y_position: y_position + 75}
      :high -> %Background{background | y_position: y_position + 100}
    end
  end
end
