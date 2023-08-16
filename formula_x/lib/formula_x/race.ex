defmodule FormulaX.Race do
  @moduledoc """
  Race context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race.Background
  alias FormulaX.Race.Car
  alias FormulaX.Race.Car.Controller

  # Race distance is measured in pixels
  # To be eventually set as RACE_DISTANCE in config
  @race_distance 100_000

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
    race_distance = @race_distance
    background = Background.initialize(race_distance)

    new(%{cars: cars, background: background, distance: race_distance})
  end

  @spec start(Race.t()) :: Race.t()
  def start(race = %Race{status: :countdown}) do
    %Race{race | status: :ongoing, start_time: Time.utc_now()}
    # Task of driving computer controlled cars is transferred from here to a separate module. Try to use genserver if it makes sense.
    |> Controller.start()
  end

  @spec update_background(Race.t(), Background.t()) :: Race.t()
  def update_background(race = %Race{}, updated_background = %Background{}) do
    %Race{race | background: updated_background}
  end

  @spec update_cars(Race.t(), Car.t()) :: Race.t()
  def update_cars(race = %Race{cars: cars}, updated_car = %Car{car_id: updated_car_id}) do
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

  @spec get_car_by_id(Race.t(), integer()) :: {:ok, Car.t()} | {:error, String.t()}
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

  # This function will be used by Controller to check and steer computer driven cars and
  # To show crash sign when the player car crashes
  # Context where it will be placed is to be finalised
  @spec crash?(Race.t(), integer(), :forward | :left | :right) :: boolean()
  def crash?(
        race = %Race{},
        check_requesting_car_id,
        movement_direction = :left
      )
      when is_integer(check_requesting_car_id) do
    {lanes_with_cars, check_requesting_car = %Car{x_position: check_requesting_car_x_position},
     check_requesting_car_lane} = get_crash_check_parameters(race, check_requesting_car_id)

    case check_requesting_car_lane do
      # Possibility of crash with a background item ouside the first lane on the left side
      1 ->
        # '0' is the left side limit for first lane
        if check_requesting_car_x_position <= 0 do
          true
        else
          false
        end

      # Lane 2 or 3
      # Possibility of crash with a car on the left lane
      lane ->
        left_lane_cars = Map.get(lanes_with_cars, lane - 1, [])

        check_requesting_car_after_steering_left =
          Car.steer(check_requesting_car, movement_direction)

        Enum.any?(left_lane_cars, fn left_lane_car ->
          crash_between_cars?(left_lane_car, check_requesting_car_after_steering_left)
        end)
    end
  end

  def crash?(
        race = %Race{},
        check_requesting_car_id,
        movement_direction = :right
      )
      when is_integer(check_requesting_car_id) do
    {lanes_with_cars, check_requesting_car = %Car{x_position: check_requesting_car_x_position},
     check_requesting_car_lane} = get_crash_check_parameters(race, check_requesting_car_id)

    case check_requesting_car_lane do
      # Possibility of crash with a background item ouside the third lane on the right side
      3 ->
        # '230' is the right side limit for 3rd lane

        if 230 - check_requesting_car_x_position <= 0 do
          true
        else
          false
        end

      # Lane 1 or 2
      lane ->
        right_lane_cars = Map.get(lanes_with_cars, lane + 1, [])

        check_requesting_car_after_steering_right =
          Car.steer(check_requesting_car, movement_direction)

        Enum.any?(right_lane_cars, fn right_lane_car ->
          crash_between_cars?(right_lane_car, check_requesting_car_after_steering_right)
        end)
    end
  end

  def crash?(
        _race = %Race{},
        check_requesting_car_id,
        _movement_direction = :forward
      )
      when is_integer(check_requesting_car_id) do
    # To be done
  end

  @spec get_crash_check_parameters(Race.t(), integer()) :: {map(), Car.t(), integer()}
  defp get_crash_check_parameters(race = %Race{cars: cars}, check_requesting_car_id)
       when is_integer(check_requesting_car_id) do
    lanes_with_cars = Enum.group_by(cars, &Car.get_lane/1, & &1)

    {:ok, check_requesting_car} = get_car_by_id(race, check_requesting_car_id)
    check_requesting_car_lane = Car.get_lane(check_requesting_car)
    {lanes_with_cars, check_requesting_car, check_requesting_car_lane}
  end

  @spec crash_between_cars?(Car.t(), Car.t()) :: boolean()
  defp crash_between_cars?(car1 = %Car{}, car2 = %{}) do
    car1_border_coordinates = get_car_border_coordinates(car1)
    car2_border_coordinates = get_car_border_coordinates(car2)

    # To see if there is an intersection of borders
    car1_border_coordinates
    |> Enum.any?(fn car1_border_coordinate ->
      Enum.member?(car2_border_coordinates, car1_border_coordinate)
    end)
  end

  @spec get_car_border_coordinates(Car.t()) :: list({integer(), integer()})
  defp get_car_border_coordinates(%Car{x_position: car_edge_1_x, y_position: car_edge_1_y}) do
    # A car is 56px wide and 112px long
    side_1_points = Enum.map(car_edge_1_x..(car_edge_1_x + 56), fn x -> {x, car_edge_1_y} end)

    side_2_points =
      Enum.map(car_edge_1_x..(car_edge_1_x + 56), fn x -> {x, car_edge_1_y + 112} end)

    side_3_points = Enum.map(car_edge_1_y..(car_edge_1_y + 112), fn y -> {car_edge_1_x, y} end)

    side_4_points =
      Enum.map(car_edge_1_y..(car_edge_1_y + 112), fn y -> {car_edge_1_x + 56, y} end)

    side_1_points ++ side_2_points ++ side_3_points ++ side_4_points
  end
end
