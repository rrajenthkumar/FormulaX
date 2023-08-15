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

    # Race distance is measured in pixels
    # To be eventually set as RACE_DISTANCE in config
    race_distance = 100_000
    background = Background.initialize(race_distance)

    new(%{cars: cars, background: background, distance: race_distance})
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

  # Below 3 functions are to be improved to have only the coordinates
  # actually relevant during car movements forward and sidewards
  # The sidewards movement is lagging now
  @spec crash?(Race.t(), Car.t()) :: boolean()
  def crash?(
        %Race{cars: cars},
        requesting_car = %Car{}
      ) do
    crash_zone_coordinates = get_crash_zone_coordinates(cars, requesting_car)

    requesting_car
    |> get_car_coordinates()
    |> Enum.map(fn car_coordinate ->
      Enum.any?(crash_zone_coordinates, fn crash_zone_coordinate ->
        crash_zone_coordinate == car_coordinate
      end)
    end)
    |> Enum.any?()
  end

  @spec get_crash_zone_coordinates(list(Car.t()), Car.t()) :: list({integer(), integer()})
  defp get_crash_zone_coordinates(cars, requesting_car = %Car{}) when is_list(cars) do
    cars
    |> Enum.reject(fn car -> car.car_id == requesting_car.car_id end)
    |> Enum.flat_map(fn car -> get_car_coordinates(car) end)
  end

  @spec get_car_coordinates(Car.t()) :: list({integer(), integer()})
  defp get_car_coordinates(%Car{x_position: car_edge_x, y_position: car_edge_y}) do
    # A car is 56px wide and 112px long
    opposite_car_edge_x = car_edge_x + 56
    opposite_car_edge_y = car_edge_y + 112

    Enum.flat_map(car_edge_x..opposite_car_edge_x, fn x ->
      Enum.map(car_edge_y..opposite_car_edge_y, fn y -> {x, y} end)
    end)
  end
end
