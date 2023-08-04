defmodule FormulaX.Race do
  @moduledoc """
  Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Commander
  alias FormulaX.Utils

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
    cars = initialize_cars()

    background = Background.initialize()

    # To be eventually set as RACE_DISTANCE in config
    distance = 100_000

    new(%{cars: cars, background: background, distance: distance})
  end

  @spec initialize_cars() :: list(Car.t())
  defp initialize_cars() do
    possible_ids = [1, 2, 3, 4, 5, 6]
    player_car_id = Enum.random(possible_ids)

    available_car_images = Utils.get_images("cars")
    player_car_image = Enum.random(available_car_images)

    player_car = Car.initialize(player_car_id, player_car_image, :player)

    remaining_ids = possible_ids -- [player_car_id]
    remaining_car_images = available_car_images -- [player_car_image]

    computer_controlled_cars =
      initialize_computer_controlled_cars(remaining_ids, remaining_car_images)

    computer_controlled_cars ++ [player_car]
  end

  @spec initialize_computer_controlled_cars(list(), list()) :: list(Car.t())
  defp initialize_computer_controlled_cars([car_id], car_images) do
    car_image = Enum.random(car_images)

    [Car.initialize(car_id, car_image, :computer)]
  end

  defp initialize_computer_controlled_cars(_car_ids = [head | tail], car_images) do
    car_image = Enum.random(car_images)

    car = Car.initialize(head, car_image, :computer)

    remaining_car_images = car_images -- [car_image]

    [car] ++ initialize_computer_controlled_cars(tail, remaining_car_images)
  end

  @spec start(Race.t()) :: Race.t()
  def start(race = %Race{status: :countdown}) do
    %Race{race | status: :ongoing, start_time: Time.utc_now()}
    # Task of driving computer controlled cars is transferred from here to a separate module
    |> Commander.start_computer_controlled_cars()
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
