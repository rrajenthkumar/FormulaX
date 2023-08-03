defmodule FormulaX.Race.Background do
  @moduledoc """
  Background context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Utils
  alias FormulaX.Race

  # Every grid (100px wide) on each side holds an image of one of the available background items like a tree, a rock, a building etc
  # To be eventually calculated from config (RACE_DISTANCE)
  @number_of_grids 1000

  @type image_path :: String.t()
  @typedoc "List of backgound image paths"
  @type image_paths :: list(image_path())

  @typedoc "Background struct"
  typedstruct do
    field(:left_side_images, image_paths(), enforce: true)
    field(:right_side_images, image_paths(), enforce: true)
    field(:distance_covered, Race.distance(), default: 0)
  end

  @spec new(map()) :: Background.t()
  def new(attrs) when is_map(attrs) do
    struct!(Background, attrs)
  end

  @spec initialize() :: Background.t()
  def initialize() do
    available_background_images = Utils.get_image_paths("/images/background")
    left_side_images = generate_side_images(available_background_images)
    right_side_images = generate_side_images(available_background_images)

    new(%{left_side_images: left_side_images, right_side_images: right_side_images})
  end

  @spec generate_side_images(image_paths()) :: image_paths()
  defp generate_side_images(available_background_images) do
    Enum.map(1..@number_of_grids, fn _grid_number -> Enum.random(available_background_images) end)
  end

  @spec increment_distance_covered(Background.t()) :: Background.t()
  def increment_distance_covered(background = %Background{distance_covered: distance_covered}) do
    %Background{background | distance_covered: distance_covered + 1}
  end
end
