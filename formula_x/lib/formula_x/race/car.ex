defmodule FormulaX.Race.Car do
  @moduledoc """
  **Car context**
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Parameters
  alias FormulaX.Utils

  @number_of_cars Parameters.number_of_cars()
  @car_steering_step Parameters.car_steering_step()

  @type filename :: String.t()
  @type controller :: :player | :autonomous
  @type speed :: :rest | :low | :moderate | :high
  @type coordinates :: {Parameters.pixel(), Parameters.pixel()}

  @typedoc "Car struct"
  typedstruct do
    field(:id, integer(), enforce: true)
    field(:image, filename(), enforce: true)
    field(:controller, controller(), enforce: true)
    field(:x_position, Parameters.pixel(), enforce: true)
    field(:y_position, Parameters.pixel(), enforce: true)
    field(:speed, speed(), enforce: true)
    field(:distance_travelled, Parameters.pixel(), default: 0)
    field(:completion_time, Time.t(), default: nil)
  end

  @spec new(map()) :: Car.t()
  def new(attrs) when is_map(attrs) do
    struct!(Car, attrs)
  end

  @spec initialize_cars(integer()) :: list(Car.t())
  def initialize_cars(player_car_index) when is_integer(player_car_index) do
    possible_ids =
      1..@number_of_cars
      |> Enum.to_list()

    player_car_id = Enum.random(possible_ids)

    available_car_images = Utils.get_images("cars")

    player_car_image = Enum.at(available_car_images, player_car_index)

    player_car = initialize_car(player_car_id, player_car_image, :player)

    remaining_ids = possible_ids -- [player_car_id]
    remaining_car_images = available_car_images -- [player_car_image]

    autonomous_cars = initialize_autonomous_cars(remaining_ids, remaining_car_images)

    autonomous_cars ++ [player_car]
  end

  @spec drive(Car.t()) :: Car.t()
  def drive(
        car = %Car{
          speed: speed,
          distance_travelled: distance_travelled
        }
      ) do
    %Car{
      car
      | distance_travelled: distance_travelled + Parameters.car_drive_step(speed)
    }
  end

  @doc """
  Function to position autonomous cars correctly w.r.t player car position on screen.
  """
  @spec adapt_autonomous_car_position(Car.t(), Race.t()) :: Car.t()
  def adapt_autonomous_car_position(
        car = %Car{
          id: car_id,
          distance_travelled: distance_travelled_by_autonomous_car,
          controller: :autonomous
        },
        race = %Race{}
      ) do
    %Car{distance_travelled: distance_travelled_by_player_car} = Race.get_player_car(race)

    {_, starting_y_position} = get_starting_x_and_y_positions(car_id)

    updated_y_position =
      starting_y_position +
        distance_travelled_by_autonomous_car -
        distance_travelled_by_player_car

    %Car{car | y_position: updated_y_position}
  end

  @spec steer(Car.t(), :left | :right) :: Car.t()
  def steer(car = %Car{x_position: x_position}, :left) do
    %Car{car | x_position: x_position - @car_steering_step}
  end

  def steer(car = %Car{x_position: x_position}, :right) do
    %Car{car | x_position: x_position + @car_steering_step}
  end

  @spec change_speed(Car.t(), :speedup | :slowdown) :: Car.t()
  def change_speed(car = %Car{speed: :rest}, _action = :speedup) do
    %Car{car | speed: :low}
  end

  def change_speed(car = %Car{speed: :low}, _action = :speedup) do
    %Car{car | speed: :moderate}
  end

  def change_speed(car = %Car{speed: :moderate}, _action = :speedup) do
    %Car{car | speed: :high}
  end

  def change_speed(car = %Car{speed: :high}, _action = :speedup) do
    car
  end

  def change_speed(car = %Car{speed: :rest}, _action = :slowdown) do
    car
  end

  def change_speed(car = %Car{speed: :low}, _action = :slowdown) do
    %Car{car | speed: :rest}
  end

  def change_speed(car = %Car{speed: :moderate}, _action = :slowdown) do
    %Car{car | speed: :low}
  end

  def change_speed(car = %Car{speed: :high}, _action = :slowdown) do
    %Car{car | speed: :moderate}
  end

  @spec stop(Car.t()) :: Car.t()
  def stop(car = %Car{}) do
    %Car{car | speed: :rest}
  end

  @spec add_completion_time_if_finished(Car.t(), Race.t()) :: Car.t()
  def add_completion_time_if_finished(car = %Car{completion_time: nil}, race = %Race{}) do
    case finished?(car, race) do
      true -> %Car{car | completion_time: Time.utc_now()}
      false -> car
    end
  end

  def add_completion_time_if_finished(car = %Car{}, %Race{}) do
    car
  end

  @spec finished?(Car.t(), Race.t()) :: boolean()
  defp finished?(
         %Car{distance_travelled: distance_travelled_by_car},
         %Race{distance: race_distance}
       ) do
    distance_travelled_by_car >= race_distance
  end

  @spec get_lane(Car.t()) :: integer() | :out_of_tracks
  def get_lane(%Car{x_position: car_x_position}) do
    Parameters.lanes()
    |> Enum.find(fn %{x_start: lane_x_start, x_end: lane_x_end} ->
      car_x_position in lane_x_start..lane_x_end
    end)
    |> case do
      nil -> :out_of_tracks
      lane_map -> Map.fetch!(lane_map, :lane_number)
    end
  end

  @spec initialize_autonomous_cars(list(integer()), list(filename())) :: list(Car.t())
  defp initialize_autonomous_cars([car_id], car_images) when is_list(car_images) do
    car_image = Enum.random(car_images)

    [initialize_car(car_id, car_image, :autonomous)]
  end

  defp initialize_autonomous_cars(_car_ids = [head | tail], car_images)
       when is_list(car_images) do
    car_image = Enum.random(car_images)

    car = initialize_car(head, car_image, :autonomous)

    remaining_car_images = car_images -- [car_image]

    [car] ++ initialize_autonomous_cars(tail, remaining_car_images)
  end

  # Please note that the origin point of every car is at its left bottom edge.
  @spec initialize_car(integer(), filename(), controller()) :: Car.t()
  defp initialize_car(car_id, image, controller = :player)
       when is_integer(car_id) and is_binary(image) do
    {x_position, y_position} = get_starting_x_and_y_positions(car_id)

    new(%{
      id: car_id,
      image: image,
      controller: controller,
      x_position: x_position,
      y_position: y_position,
      speed: :rest
    })
  end

  defp initialize_car(car_id, image, controller)
       when is_integer(car_id) and is_binary(image) and is_atom(controller) do
    {x_position, y_position} = get_starting_x_and_y_positions(car_id)
    speed = Enum.random([:low, :moderate, :high])

    new(%{
      id: car_id,
      image: image,
      controller: controller,
      x_position: x_position,
      y_position: y_position,
      speed: speed
    })
  end

  @spec get_starting_x_and_y_positions(integer()) :: coordinates()
  defp get_starting_x_and_y_positions(car_id) when is_integer(car_id) do
    Parameters.car_initial_positions()
    |> Enum.at(car_id - 1)
  end
end
