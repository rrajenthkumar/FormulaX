defmodule FormulaX.Race do
  @moduledoc """
  **Race context**
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Parameters

  @type cars :: list(Car.t())
  @typedoc """
  Distance refers to number of pixels of the screen, cars have to traverse in a race in total, in Y direction.
  """
  @type distance :: integer()
  @type status :: :countdown | :ongoing | :aborted | :completed

  @typedoc "Race struct"
  typedstruct do
    field(:cars, cars(), enforce: true)
    field(:background, Background.t(), enforce: true)
    field(:start_time, Time.t(), default: nil)
    field(:distance, distance(), enforce: true)
    field(:status, status(), default: :countdown)
  end

  @spec new(map()) :: Race.t()
  def new(attrs) when is_map(attrs) do
    struct!(Race, attrs)
  end

  @spec initialize() :: Race.t()
  def initialize() do
    cars = Car.initialize_cars()
    race_distance = Parameters.race_distance()
    background = Background.initialize(race_distance)

    new(%{cars: cars, background: background, distance: race_distance})
  end

  @spec start(Race.t()) :: Race.t()
  def start(race = %Race{status: :countdown}) do
    %Race{race | status: :ongoing, start_time: Time.utc_now()}
  end

  @spec update_background(Race.t(), Background.t()) :: Race.t()
  def update_background(race = %Race{}, updated_background = %Background{}) do
    %Race{race | background: updated_background}
  end

  @spec update_car(Race.t(), Car.t()) :: Race.t()
  def update_car(race = %Race{cars: cars}, updated_car = %Car{car_id: updated_car_id}) do
    updated_cars =
      Enum.map(cars, fn car ->
        if car.car_id == updated_car_id do
          updated_car
        else
          car
        end
      end)

    %Race{race | cars: updated_cars}
  end

  @spec abort(Race.t()) :: Race.t()
  def abort(race = %Race{status: :ongoing}) do
    %Race{race | status: :aborted}
  end

  @spec complete(Race.t()) :: Race.t()
  def complete(race = %Race{status: :ongoing}) do
    %Race{race | status: :completed}
  end

  @spec get_car_by_id(Race.t(), Car.car_id()) :: {:ok, Car.t()} | {:error, String.t()}
  def get_car_by_id(%Race{cars: cars}, car_id) when is_integer(car_id) do
    result = Enum.find(cars, fn car -> car.car_id == car_id end)

    case result do
      nil -> {:error, "car not found"}
      result -> {:ok, result}
    end
  end

  @spec get_player_car(Race.t()) :: Car.t()
  def get_player_car(%Race{cars: cars}) do
    Enum.find(cars, fn car -> car.controller == :player end)
  end
end
