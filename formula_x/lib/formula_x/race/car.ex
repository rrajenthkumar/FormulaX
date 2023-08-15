defmodule FormulaX.Race.Car do
  @moduledoc """
  Car context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Utils

  @typedoc "There will be 6 cars in total in a race"
  @type car_id :: 1..6
  @type filename :: String.t()
  @type controller :: :player | :computer
  @typedoc "Position on screen in pixels where the car appears along the X direction"
  @type x_position :: integer()
  @typedoc "Position on screen in pixels where the car appears along the Y direction"
  @type y_position :: integer()
  @type speed :: :rest | :low | :moderate | :high

  @typedoc "Car struct"
  typedstruct do
    field(:car_id, car_id(), enforce: true)
    field(:image, filename(), enforce: true)
    field(:controller, controller(), enforce: true)
    field(:x_position, x_position(), enforce: true)
    field(:y_position, y_position(), enforce: true)
    field(:speed, speed(), default: :moderate)
    field(:completion_time, Time.t(), default: nil)
  end

  @spec new(map()) :: Car.t()
  def new(attrs) when is_map(attrs) do
    struct!(Car, attrs)
  end

  @spec initialize_cars() :: list(Car.t())
  def initialize_cars() do
    possible_ids = [1, 2, 3, 4, 5, 6]
    player_car_id = Enum.random(possible_ids)

    available_car_images = Utils.get_images("cars")
    player_car_image = Enum.random(available_car_images)

    player_car = initialize_car(player_car_id, player_car_image, :player)

    remaining_ids = possible_ids -- [player_car_id]
    remaining_car_images = available_car_images -- [player_car_image]

    computer_controlled_cars =
      initialize_computer_controlled_cars(remaining_ids, remaining_car_images)

    computer_controlled_cars ++ [player_car]
  end

  @spec initialize_computer_controlled_cars(list(), list()) :: list(Car.t())
  defp initialize_computer_controlled_cars([car_id], car_images) do
    car_image = Enum.random(car_images)

    [initialize_car(car_id, car_image, :computer)]
  end

  defp initialize_computer_controlled_cars(_car_ids = [head | tail], car_images) do
    car_image = Enum.random(car_images)

    car = initialize_car(head, car_image, :computer)

    remaining_car_images = car_images -- [car_image]

    [car] ++ initialize_computer_controlled_cars(tail, remaining_car_images)
  end

  defp initialize_car(car_id, image, controller) do
    {x_position, y_position} = get_starting_x_and_y_positions(car_id)

    new(%{
      car_id: car_id,
      image: image,
      controller: controller,
      x_position: x_position,
      y_position: y_position
    })
  end

  @spec get_player_car(list(Car.t())) :: Car.t()
  def get_player_car(cars) do
    Enum.find(cars, fn car -> car.controller == :player end)
  end

  @spec update_cars(list(Car.t()), Car.t()) :: list(Car.t())
  def update_cars(cars, updated_car) do
    Enum.map(cars, fn car ->
      if car.car_id == updated_car.car_id do
        updated_car
      else
        car
      end
    end)
  end

  # To move a car sidewards check if there is no other car on the side to be moved to
  # and if the car has not already reached the edge
  @spec steer(Car.t(), :left | :right) :: Car.t()
  def steer(car = %Car{x_position: x_position}, :left) do
    %Car{car | x_position: x_position - 10}
  end

  def steer(car = %Car{x_position: x_position}, :right) do
    %Car{car | x_position: x_position + 10}
  end

  @spec change_speed(Car.t(), :accelerate | :decelerate) :: Car.t()
  def change_speed(car = %Car{speed: :rest}, :accelerate) do
    %Car{car | speed: :slow}
  end

  def change_speed(car = %Car{speed: :slow}, :accelerate) do
    %Car{car | speed: :moderate}
  end

  def change_speed(car = %Car{speed: :moderate}, :accelerate) do
    %Car{car | speed: :high}
  end

  def change_speed(car = %Car{speed: :high}, :decelerate) do
    %Car{car | speed: :moderate}
  end

  def change_speed(car = %Car{speed: :moderate}, :decelerate) do
    %Car{car | speed: :slow}
  end

  def change_speed(car = %Car{speed: :slow}, :decelerate) do
    %Car{car | speed: :rest}
  end

  def change_speed(car = %Car{}, _action) do
    car
  end

  # The x and y positions are in pixels
  @spec get_starting_x_and_y_positions(integer()) :: {integer(), integer()}
  defp get_starting_x_and_y_positions(1) do
    {18, 0}
  end

  defp get_starting_x_and_y_positions(2) do
    {18, 130}
  end

  defp get_starting_x_and_y_positions(3) do
    {116, 0}
  end

  defp get_starting_x_and_y_positions(4) do
    {116, 130}
  end

  defp get_starting_x_and_y_positions(5) do
    {214, 0}
  end

  defp get_starting_x_and_y_positions(6) do
    {214, 130}
  end
end
