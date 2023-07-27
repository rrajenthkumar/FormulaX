defmodule FormulaX.Race do
  @moduledoc """
  Race context
  """
  use TypedStruct

  alias FormulaX.Race.Racer

  @type contestants :: list(Racer.t())
  @type status :: :countdown | :ongoing | :completed

  @typedoc """
  Distance refers to number of vertical lengths of the screen, cars have to traverse in a race.
  """
  @type distance :: integer()

  @typedoc "Formula X race struct"
  typedstruct do
    field(:contestants, contestants(), enforce: true)
    field(:total_distance, distance(), enforce: true)
    field(:status, status(), default: :countdown)
    field(:start_time, Time.t(), default: Time.utc_now())
  end
end
