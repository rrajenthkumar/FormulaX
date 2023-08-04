defmodule FormulaX.Race.Car do
  @moduledoc """
  Car context
  """
  use TypedStruct

  alias __MODULE__

  @typedoc "There will be 6 cars in total in a race"
  @type car_id :: 1..6
  @type filename :: String.t()
  @type controller :: :player | :computer
  @typedoc "Position on screen in pixels where the car appears along the X direction"
  @type x_position :: integer()
  @typedoc "Position on screen in pixels where the car appears along the Y direction"
  @type y_position :: integer()
  @type speed :: :rest | :slow | :moderate | :high

  @typedoc "Car struct"
  typedstruct do
    field(:car_id, car_id(), enforce: true)
    field(:image, filename(), enforce: true)
    field(:controller, controller(), enforce: true)
    field(:x_position, x_position(), enforce: true)
    field(:y_position, y_position(), enforce: true)
    field(:speed, speed(), default: :rest)
    field(:completion_time, Time.t(), default: nil)
  end

  @spec new(map()) :: Car.t()
  def new(attrs) when is_map(attrs) do
    struct!(Car, attrs)
  end

  def initialize(id, image, controller) do
    {x_position, y_position} = get_initial_x_and_y_positions(id)

    new(%{
      id: id,
      image: image,
      controller: controller,
      x_position: x_position,
      y_position: y_position
    })
  end

  # To change a car's track check if there is no other car on the side to be moved to and if the car has already reached the edge
  @spec change_track(Car.t(), :left | :right) :: Car.t()
  def change_track(car = %Car{x_position: x_position}, :left) do
    %Car{car | x_position: x_position - 1}
  end

  def change_track(car = %Car{x_position: x_position}, :right) do
    %Car{car | x_position: x_position + 1}
  end

  # To accelerate a car check if there is no other car directly in the front
  # To decelerate a car check if there is no other car directly at the back
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
  @spec get_initial_x_and_y_positions(integer()) :: {integer(), integer()}
  defp get_initial_x_and_y_positions(1) do
    {0, 430}
  end

  defp get_initial_x_and_y_positions(2) do
    {0, 290}
  end

  defp get_initial_x_and_y_positions(3) do
    {-100, 430}
  end

  defp get_initial_x_and_y_positions(4) do
    {-100, 290}
  end

  defp get_initial_x_and_y_positions(5) do
    {100, 430}
  end

  defp get_initial_x_and_y_positions(6) do
    {100, 290}
  end
end
