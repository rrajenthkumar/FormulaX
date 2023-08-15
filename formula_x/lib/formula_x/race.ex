defmodule FormulaX.Race do
  @moduledoc """
  Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Car.Controller

  @type cars :: list(Car.t())
  @typedoc """
  Distance refers to number of pixels of the screen, cars have to traverse in a race in total, in Y direction.
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

  @spec initialize() :: Race.t()
  def initialize() do
    cars = Car.initialize_cars()

    background = Background.initialize()

    # To be eventually set as RACE_DISTANCE in config
    distance = 100_000

    new(%{cars: cars, background: background, distance: distance})
  end

  @spec start(Race.t()) :: Race.t()
  def start(race = %Race{status: :countdown}) do
    %Race{race | status: :ongoing, start_time: Time.utc_now()}
    # Task of driving computer controlled cars is transferred from here to a separate module
    |> Controller.start()
  end

  @spec update(Race.t(), Background.t() | list(Car.t())) :: Race.t()
  def update(race = %Race{}, updated_background = %Background{}) do
    %Race{race | background: updated_background}
  end

  def update(race = %Race{}, updated_cars) when is_list(updated_cars) do
    %Race{race | cars: updated_cars}
  end

  @spec complete(Race.t()) :: Race.t()
  def complete(race = %Race{status: :ongoing}) do
    %Race{race | status: :completed}
  end

  @spec abort(Race.t()) :: Race.t()
  def abort(race = %Race{status: :ongoing}) do
    %Race{race | status: :aborted}
  end
end
