defmodule FormulaX.Race.BackgroundItem do
  @moduledoc """
  Background item context
  """
  use TypedStruct

  alias FormulaX.Racer

  @type item_type :: :trees | :hills | :audience | :buildings | :empty_space
  @typedoc "side of the screen where the background item appears"
  @type side :: :left | :right
  @typedoc "Speed at which the background items move on the screen. This speed has to match the player's car to look realistic."
  @type item_speed :: Racer.speed()

  @typedoc "Background item struct"
  typedstruct do
    field(:item_type, item_type(), enforce: true)
    field(:side, side(), enforce: true)
    field(:item_speed, item_speed(), enforce: true)
    field(:y_position, Racer.y_position(), enforce: true)
  end
end
