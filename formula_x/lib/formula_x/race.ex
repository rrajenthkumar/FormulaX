defmodule FormulaX.Race do
  @moduledoc """
  Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
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
    # Total number of cars in a race has been set to 6
    all_possible_ids = [1, 2, 3, 4, 5, 6]
    player_car_id = Enum.random(all_possible_ids)

    all_car_images = Utils.get_images("cars")
    player_car_image = Enum.random(all_car_images)

    player_controlled_car = Car.initialize(player_car_id, player_car_image, :player)

    available_ids = all_possible_ids -- [player_car_id]
    available_car_images = all_car_images -- [player_car_image]

    computer_controlled_cars =
      initialize_computer_controlled_cars(available_ids, available_car_images)

    computer_controlled_cars ++ [player_controlled_car]
  end

  @spec initialize_computer_controlled_cars(list(), list()) :: list(Car.t())
  defp initialize_computer_controlled_cars([id], available_car_images) do
    computer_controlled_car_image = Enum.random(available_car_images)

    computer_controlled_car = Car.initialize(id, computer_controlled_car_image, :computer)

    [computer_controlled_car]
  end

  defp initialize_computer_controlled_cars(_available_ids = [head | tail], available_car_images) do
    computer_controlled_car_image = Enum.random(available_car_images)

    computer_controlled_car = Car.initialize(head, computer_controlled_car_image, :computer)

    available_car_images = available_car_images -- [computer_controlled_car_image]

    [computer_controlled_car] ++ initialize_computer_controlled_cars(tail, available_car_images)
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
