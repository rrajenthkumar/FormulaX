defmodule FormulaX.Fixtures do
  @moduledoc """
  Fixtures for Car, Background, Obstacle, Speedboost, Race, Result to be used in tests
  """
  alias FormulaX.Race.Car
  alias FormulaX.Race.Background
  alias FormulaX.Race.Obstacle
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.Race
  alias FormulaX.Result

  @spec car(map()) :: Car.t()
  def car(attrs \\ %{}) when is_map(attrs) do
    %{
      id: 1,
      image: "car.png",
      controller: :player,
      x_position: 1.25,
      y_position: 9.0,
      speed: :low
    }
    |> Map.merge(attrs)
    |> Car.new()
  end

  @spec race(map()) :: Race.t()
  def race(attrs \\ %{}) when is_map(attrs) do
    %{
      player_car: car(),
      autonomous_cars: [car(%{id: 2}), car(%{id: 3}), car(%{id: 4}), car(%{id: 5}), car(%{id: 6})],
      background: background(),
      obstacles: [
        obstacle(),
        obstacle(%{x_position: 0.0, distance: 420.0}),
        obstacle(%{x_position: 12.0, distance: 480.0})
      ],
      speed_boosts: [speed_boost(), speed_boost(%{x_position: 6.0, distance: 900.0})],
      status: :ongoing,
      distance: 1000.0
    }
    |> Map.merge(attrs)
    |> Race.new()
  end

  @spec background(map()) :: Background.t()
  def background(attrs \\ %{}) when is_map(attrs) do
    %{
      left_side_images: [
        "image1.png",
        "image2.png",
        "image3.png",
        "image4.png",
        "image5.png",
        "image6.png",
        "image7.png",
        "image8.png",
        "image9.png",
        "image10.png"
      ],
      right_side_images: [
        "image10.png",
        "image9.png",
        "image8.png",
        "image7.png",
        "image6.png",
        "image5.png",
        "image4.png",
        "image3.png",
        "image2.png",
        "image1.png"
      ],
      y_position: -1035.0
    }
    |> Map.merge(attrs)
    |> Background.new()
  end

  @spec obstacle(map()) :: Obstacle.t()
  def obstacle(attrs \\ %{}) when is_map(attrs) do
    %{
      x_position: 6.0,
      distance: 390.0
    }
    |> Map.merge(attrs)
    |> Obstacle.new()
  end

  @spec speed_boost(map()) :: SpeedBoost.t()
  def speed_boost(attrs \\ %{}) when is_map(attrs) do
    %{
      x_position: 12.0,
      distance: 600.0
    }
    |> Map.merge(attrs)
    |> SpeedBoost.new()
  end

  @spec result(map()) :: Result.t()
  def result(attrs \\ %{}) when is_map(attrs) do
    %{
      car: "car.png",
      status: :completed
    }
    |> Map.merge(attrs)
    |> Result.new()
  end
end
