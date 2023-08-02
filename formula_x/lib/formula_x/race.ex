defmodule FormulaX.Race do
  @moduledoc """
  The Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Car
  alias FormulaX.Race.Background

  @type cars :: list(Car.t())
  @typedoc """
  Distance refers to number of pixels of the screen, cars have to traverse in a race, in Y direction.
  """
  @type distance :: integer()
  @type status :: :countdown | :ongoing | :completed

  @typedoc "Race struct"
  typedstruct do
    field(:cars, cars(), enforce: true)
    field(:background, Background.t(), enforce: true)
    field(:distance, distance(), enforce: true)
    field(:status, status(), default: :countdown)
    field(:start_time, Time.t(), default: nil)
  end

  @spec new(map()) :: Race.t()
  def new(attrs) when is_map(attrs) do
    struct!(Race, attrs)
  end

  @spec initiate() :: Race.t()
  def initiate() do
    cars = initiate_cars()
    background = Background.initiate()
    # To be eventually set as RACE_DISTANCE in config
    distance = 100_000
    new(%{cars: cars, background: background, distance: distance})
  end

  @spec initiate_cars() :: list(Car.t())
  def initiate_cars() do
    # Loop and initiate 5 computer driven cars and one player car
    # Task of initiating induvidual cars is transferred from here to the car module
  end

  @spec start(Race.t()) :: Race.t()
  def start(race = %Race{status: :countdown}) do
    %Race{race | status: :ongoing, start_time: Time.utc_now()}
  end

  @spec control_computer_driven_cars(Race.t()) :: Race.t()
  def control_computer_driven_cars(_race = %Race{}) do
    # Task of controlling induvidual cars is transferred from here to the car module or a separate module if needed
  end

  @spec complete(Race.t()) :: Race.t()
  def complete(race = %Race{status: :ongoing}) do
    %Race{race | status: :completed}
  end
end
