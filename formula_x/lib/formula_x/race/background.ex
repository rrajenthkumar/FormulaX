defmodule FormulaX.Race.Background do
  @moduledoc """
  Background context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Utils

  # Background images are shown on both left and right sides.
  # Images can be of a tree, a rock, a building etc
  # The total number of images per side decides the distance of the race
  # and will eventually be read from config (RACE_DISTANCE)
  # 1 image will result in 200px of race distance
  @number_of_images_per_side 1000

  @type filename :: String.t()
  @type filenames :: list(filename())
  @typedoc "Position on screen in pixels to which both left and right side background sections have to be offsetted in Y direction, so that the player car appears to move along the Y direction"
  @type y_position :: integer()

  @typedoc "Background struct"
  typedstruct do
    field(:left_side_images, filenames(), enforce: true)
    field(:right_side_images, filenames(), enforce: true)
    field(:y_position, y_position(), default: -199_400)
  end

  @spec new(map()) :: Background.t()
  def new(attrs) when is_map(attrs) do
    struct!(Background, attrs)
  end

  @spec initialize() :: Background.t()
  def initialize() do
    available_background_images = Utils.get_images("backgrounds")
    left_side_images = get_side_images(available_background_images)
    right_side_images = get_side_images(available_background_images)

    new(%{left_side_images: left_side_images, right_side_images: right_side_images})
  end

  @spec get_side_images(filenames()) :: filenames()
  defp get_side_images(available_background_images) do
    Enum.map(1..@number_of_images_per_side, fn _grid_number ->
      Enum.random(available_background_images)
    end)
  end

  @spec offset(Background.t()) :: Background.t()
  def offset(background = %Background{y_position: y_position}) do
    %Background{background | y_position: y_position + 100}
  end
end
