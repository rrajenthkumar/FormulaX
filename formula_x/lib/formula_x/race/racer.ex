defmodule FormulaX.Race.Racer do
  @moduledoc """
  Racer context
  """
  use TypedStruct

  alias FormulaX.Race

  @type racer_type :: :player | :computer
  @type car_model :: :model1 | :model2 | :model3 | :model4
  @typedoc """
  Center point of a car is assumed to be at the common midpoint of the car along it's both axes.
  X axis of the screen is split into 5 segments starting with 0 at the horizontal center of the screen
  and ending at -2 and 2 at the left and right edges respectively.
  The width of a car is assumed to be 1 unit along X axis.
  """
  @type x_position :: -2..2
  @typedoc """
  Y axis of the screen is split into 10 segments starting with 0 at the bottom edge and ending with 10 at the top edge.
  The length of a car is considered to be 2 units along Y axis.
  """
  @type y_position :: 0..10
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
