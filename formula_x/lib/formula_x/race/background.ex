defmodule FormulaX.Race.Background do
  @moduledoc """
  Background context
  """
  use TypedStruct

  alias FormulaX.Racer

  @type items :: list(item())
  @typedoc "side of the screen where the background item appears"
  @type side :: :left | :right

  @typedoc "Background item struct"
  typedstruct do
    field(:items, items(), enforce: true)
    field(:side, side(), enforce: true)
    field(:y_position, Racer.y_position(), default: 0)
  end
end
