defmodule FormulaX.Race.Racer do
  @moduledoc """
  Racer context
  """
  use TypedStruct

  alias FormulaX.Race

  @type racer_type :: :player | :computer
  @type car_model :: :model1 | :model2 | :model3 | :model4
  @typedoc """
  Position from right side of the gaming console screen in pixels
  """
  @type x_position :: integer()
  @typedoc """
  Position from top of the gaming console screen in pixels
  """
  @type y_position :: integer()
  @type speed :: :rest | :slow | :moderate | :high

  @typedoc "Racer struct"
  typedstruct do
    field(:id, integer(), enforce: true)
    field(:name, String.t(), enforce: true)
    field(:racer_type, racer_type(), default: :computer)
    field(:car_model, car_model(), enforce: true)
    field(:x_position, x_position(), enforce: true)
    field(:y_position, y_position(), enforce: true)
    field(:speed, speed(), default: :rest)
    field(:remaining_distance, Race.distance(), enforce: true)
    field(:completion_time, Time.t(), default: nil)
  end
end
