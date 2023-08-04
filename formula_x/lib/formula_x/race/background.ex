defmodule FormulaX.Race.Background do
  @moduledoc """
  Background context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Utils

  # Every grid element (100px wide) holds an image of one of the available background items like a tree, a rock, a building etc
  # To be eventually calculated from config (RACE_DISTANCE)
  @number_of_grid_elements 1000

  @type filename :: String.t()
  @type filenames :: list(filename())
  @typedoc "Position on screen in pixels to which both left and right side background sections have to be offsetted in Y direction, so that the player car appears to move along the Y direction"
  @type y_position :: integer()

  @typedoc "Background struct"
  typedstruct do
    field(:left_grid, filenames(), enforce: true)
    field(:right_grid, filenames(), enforce: true)
    field(:y_position, y_position(), default: 0)
  end

  @spec new(map()) :: Background.t()
  def new(attrs) when is_map(attrs) do
    struct!(Background, attrs)
  end

  @spec initialize() :: Background.t()
  def initialize() do
    available_background_images = Utils.get_images("backgrounds")
    left_grid = generate_grid(available_background_images)
    right_grid = generate_grid(available_background_images)

    new(%{left_grid: left_grid, right_grid: right_grid})
  end

  @spec generate_grid(filenames()) :: filenames()
  defp generate_grid(available_background_images) do
    Enum.map(1..@number_of_grid_elements, fn _grid_number ->
      Enum.random(available_background_images)
    end)
  end

  @spec offset(Background.t()) :: Background.t()
  def offset(background = %Background{y_position: y_position}) do
    %Background{background | y_position: y_position + 1}
  end
end
