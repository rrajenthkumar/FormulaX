defmodule FormulaX.Race.Car do
  @moduledoc """
  Car context
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Race.Background
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
  @type coordinate :: {x_position(), y_position()}

  @typedoc "Car struct"
  typedstruct do
    field(:car_id, car_id(), enforce: true)
    field(:image, filename(), enforce: true)
    field(:controller, controller(), enforce: true)
    field(:x_position, x_position(), enforce: true)
    field(:y_position, y_position(), enforce: true)
    field(:speed, speed(), enforce: true)
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

  @spec initialize_computer_controlled_cars(list(car_id()), list(filename())) :: list(Car.t())
  defp initialize_computer_controlled_cars([car_id], car_images) when is_list(car_images) do
    car_image = Enum.random(car_images)

    [initialize_car(car_id, car_image, :computer)]
  end

  defp initialize_computer_controlled_cars(_car_ids = [head | tail], car_images)
       when is_list(car_images) do
    car_image = Enum.random(car_images)

    car = initialize_car(head, car_image, :computer)

    remaining_car_images = car_images -- [car_image]

    [car] ++ initialize_computer_controlled_cars(tail, remaining_car_images)
  end

  @spec initialize_car(car_id(), filename(), controller()) :: Car.t()
  defp initialize_car(car_id, image, controller)
       when is_integer(car_id) and is_binary(image) and is_atom(controller) do
    {x_position, y_position} = get_starting_x_and_y_positions(car_id)
    speed = Enum.random([:low, :moderate, :high])

    new(%{
      car_id: car_id,
      image: image,
      controller: controller,
      x_position: x_position,
      y_position: y_position,
      speed: speed
    })
  end

  @spec steer(Car.t(), :left | :right) :: Car.t()
  def steer(car = %Car{x_position: x_position}, :left) do
    %Car{car | x_position: x_position - 5}
  end

  def steer(car = %Car{x_position: x_position}, :right) do
    %Car{car | x_position: x_position + 5}
  end

  @spec drive(Car.t()) :: Car.t()
  def drive(car = %Car{speed: :rest}) do
    car
  end

  def drive(
        car = %Car{
          y_position: y_position,
          speed: :low
        }
      ) do
    updated_y_position = y_position + 50
    %Car{car | y_position: updated_y_position}
  end

  def drive(car = %Car{y_position: y_position, speed: :moderate}) do
    updated_y_position = y_position + 75
    %Car{car | y_position: updated_y_position}
  end

  def drive(car = %Car{y_position: y_position, speed: :high}) do
    updated_y_position = y_position + 100
    %Car{car | y_position: updated_y_position}
  end

  @spec accelerate(Car.t()) :: Car.t()
  def accelerate(car = %Car{speed: :rest}) do
    %Car{car | speed: :low}
  end

  def accelerate(car = %Car{speed: :low}) do
    %Car{car | speed: :moderate}
  end

  def accelerate(car = %Car{speed: :moderate}) do
    %Car{car | speed: :high}
  end

  def accelerate(car = %Car{speed: :high}) do
    car
  end

  @spec decelerate(Car.t()) :: Car.t()
  def decelerate(car = %Car{speed: :rest}) do
    car
  end

  def decelerate(car = %Car{speed: :low}) do
    %Car{car | speed: :rest}
  end

  def decelerate(car = %Car{speed: :moderate}) do
    %Car{car | speed: :low}
  end

  def decelerate(car = %Car{speed: :high}) do
    %Car{car | speed: :moderate}
  end

  @spec start(Car.t()) :: Car.t()
  def start(car = %Car{speed: :rest}) do
    %Car{car | speed: :low}
  end

  @spec stop(Car.t()) :: Car.t()
  def stop(car = %Car{}) do
    %Car{car | speed: :rest}
  end

  @spec get_lane(Car.t()) :: Car.t()
  def get_lane(%Car{x_position: x_position}) do
    cond do
      # x = 60 is the limit of right side movement of car in lane 1
      # x = 160 is the limit of right side movement of car in lane 2
      x_position <= 60 -> 1
      x_position > 60 and x_position <= 160 -> 2
      x_position > 160 -> 3
    end
  end

  @doc """
  Function to find the correct position of computer controlled cars on the screen

  This is done because the background has already been offset by the value '- race_distance + 560px' in Y direction, to shift its origin to the origin of cars.
  Also the 'background_y_position' value reflects the correct position of player car. SO we have to adjust the computer controlled cars w.r.t background position.
  """
  @spec adapt_car_position_with_reference_to_background(Car.t(), Race.t()) :: Car.t()
  def adapt_car_position_with_reference_to_background(
        car = %Car{y_position: car_y_position},
        %Race{
          distance: race_distance,
          background: %Background{y_position: background_y_position}
        }
      ) do
    adapted_car_y_position = car_y_position - (background_y_position - 560 + race_distance)

    %Car{car | y_position: adapted_car_y_position}
  end

  # The x and y positions are in pixels from the orign at the left bottom corner of left racing lane
  @spec get_starting_x_and_y_positions(car_id()) :: coordinate()
  defp get_starting_x_and_y_positions(1) do
    {18, 0}
  end

  defp get_starting_x_and_y_positions(2) do
    {18, 115}
  end

  defp get_starting_x_and_y_positions(3) do
    {116, 0}
  end

  defp get_starting_x_and_y_positions(4) do
    {116, 115}
  end

  defp get_starting_x_and_y_positions(5) do
    {214, 0}
  end

  defp get_starting_x_and_y_positions(6) do
    {214, 115}
  end
end
