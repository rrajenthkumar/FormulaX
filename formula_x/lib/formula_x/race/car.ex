defmodule FormulaX.Race.Car do
  @moduledoc """
  **Car context**
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Race.Background
  alias FormulaX.Race.Parameters
  alias FormulaX.Utils

  @type car_id :: integer()
  @type filename :: String.t()
  @type controller :: :player | :computer
  @typedoc "Position on screen in pixels where the car appears along the X direction"
  @type x_position :: integer()
  @typedoc "Position on screen in pixels where the car appears along the Y direction"
  @type y_position :: integer()
  @type speed :: :rest | :low | :moderate | :high
  @type coordinates :: {x_position(), y_position()}

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
    possible_ids =
      1..Parameters.number_of_cars()
      |> Enum.to_list()

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
    car_sideward_movement_step = Parameters.car_sideward_movement_step()
    %Car{car | x_position: x_position - car_sideward_movement_step}
  end

  def steer(car = %Car{x_position: x_position}, :right) do
    car_sideward_movement_step = Parameters.car_sideward_movement_step()
    %Car{car | x_position: x_position + car_sideward_movement_step}
  end

  @spec drive(Car.t()) :: Car.t()

  def drive(
        car = %Car{
          y_position: y_position,
          speed: speed
        }
      ) do
    car_forward_movement_step = Parameters.car_forward_movement_step(speed)
    updated_y_position = y_position + car_forward_movement_step
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

  # TO DO: Improve
  @spec get_lane(Car.t()) :: integer()
  def get_lane(%Car{x_position: car_x_position}) do
    %{x_end: driving_area_x_end} = Parameters.driving_area_limits()

    lanes = Parameters.lanes()

    default_lane_info =
      if(car_x_position > driving_area_x_end) do
        Enum.find(lanes, fn %{lane_number: lane_number} -> lane_number == 3 end)
      else
        Enum.find(lanes, fn %{lane_number: lane_number} -> lane_number == 1 end)
      end

    lanes
    |> Enum.find(
      default_lane_info,
      fn %{x_start: lane_x_start, x_end: lane_x_end} ->
        car_x_position in lane_x_start..lane_x_end
      end
    )
    |> Map.fetch!(:lane_number)
  end

  @doc """
  Function to position computer controlled cars correctly on the screen.

  The background has already been offset by the value 'console_screen_height-race_distance' in Y direction, to shift its Y position reference to the Y position reference of cars. Also the 'background_y_position' value reflects the correct position of player car. So we have to adjust the computer controlled cars w.r.t background position.
  """
  @spec adapt_car_position_with_reference_to_background(Car.t(), Race.t()) :: Car.t()
  def adapt_car_position_with_reference_to_background(
        car = %Car{y_position: car_y_position},
        %Race{
          distance: race_distance,
          background: %Background{y_position: background_y_position}
        }
      ) do
    console_screen_height = Parameters.console_screen_height()

    adapted_car_y_position =
      car_y_position -
        (background_y_position + race_distance - console_screen_height)

    %Car{car | y_position: adapted_car_y_position}
  end

  @spec get_starting_x_and_y_positions(car_id()) :: coordinates()
  defp get_starting_x_and_y_positions(car_id) do
    Parameters.car_initial_positions()
    |> Enum.at(car_id - 1)
  end
end
