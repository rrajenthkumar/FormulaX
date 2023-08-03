defmodule FormulaX.Race.Car do
  @moduledoc """
  Car context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race

  @type image_path :: String.t()
  @type driver :: :player | :computer
  @typedoc "Position on screen where the car appears along the X direction"
  @type x_position :: integer()
  @type speed :: :rest | :slow | :moderate | :high

  @typedoc "Car struct"
  typedstruct do
    field(:id, integer(), enforce: true)
    field(:car_image, image_path(), enforce: true)
    field(:driver, driver(), enforce: true)
    field(:x_position, x_position(), enforce: true)
    field(:speed, speed(), default: :rest)
    field(:distance_covered, Race.distance(), default: 0)
    field(:completion_time, Time.t(), default: nil)
  end

  @spec new(map()) :: Car.t()
  def new(attrs) when is_map(attrs) do
    struct!(Car, attrs)
  end

  def initialize(id, car_image, driver, x_position) do
    # To initialize a car with id, car_image, driver, x_position
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
end
