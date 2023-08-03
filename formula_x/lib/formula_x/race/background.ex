defmodule FormulaX.Race.Background do
  @moduledoc """
  Background context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Utils

  # Every grid (100px wide) on each side holds an image of one of the available background items like a tree, a rock, a building etc
  # To be eventually calculated from config (RACE_DISTANCE)
  @number_of_grids 1000

  @type image_filename :: String.t()
  @type image_filenames :: list(image_filename())
  @typedoc "Position on screen in pixels to which both left and right side background sections have to be offsetted in Y direction, so that the player car appears to move along the Y direction"
  @type y_position :: integer()

  @typedoc "Background struct"
  typedstruct do
    field(:left_side, image_filenames(), enforce: true)
    field(:right_side, image_filenames(), enforce: true)
    field(:y_position, y_position(), default: 0)
  end

  @spec new(map()) :: Background.t()
  def new(attrs) when is_map(attrs) do
    struct!(Background, attrs)
  end

  @spec initialize() :: Background.t()
  def initialize() do
    available_background_images = Utils.get_images("backgrounds")
    left_side = generate_side(available_background_images)
    right_side = generate_side(available_background_images)

    new(%{left_side: left_side, right_side: right_side})
  end

  @spec generate_side(image_filenames()) :: image_filenames()
  defp generate_side(available_background_images) do
    Enum.map(1..@number_of_grids, fn _grid_number -> Enum.random(available_background_images) end)
  end

  @spec offset(Background.t()) :: Background.t()
  def offset(background = %Background{y_position: y_position}) do
    %Background{background | y_position: y_position + 1}
  end
end
