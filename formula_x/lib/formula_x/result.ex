defmodule FormulaX.Result do
  @moduledoc """
  **Result context**
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @type status :: :crash | :completed
  @type review :: :first | :good_start | :bad | :same | :improvement | :decline

  @typedoc "Result struct"
  typedstruct do
    field(:car, Car.image(), enforce: true)
    field(:status, status(), default: nil, enforce: true)
    field(:time, Time.t(), default: nil)
    field(:position, integer(), default: nil)
    field(:review, review(), default: nil)
  end

  @spec new(map()) :: Result.t()
  def new(attrs) when is_map(attrs) do
    struct!(Result, attrs)
  end

  @spec get_player_car_result(Race.t()) :: Result.t()
  def get_player_car_result(%Race{
        player_car: %Car{image: player_car_image, controller: :player},
        status: :crash
      }) do
    %{
      car: player_car_image,
      status: :crash
    }
    |> Result.new()
  end

  def get_player_car_result(%Race{
        player_car:
          player_car = %Car{
            completion_time: player_car_completion_time,
            image: player_car_image,
            controller: :player
          },
        autonomous_cars: autonomous_cars,
        start_time: race_start_time,
        status: status
      }) do
    all_cars = autonomous_cars ++ [player_car]

    player_car_index_after_finish =
      all_cars
      |> Enum.reject(fn car -> is_nil(car.completion_time) end)
      |> Enum.sort_by(& &1.completion_time, Time)
      |> Enum.find_index(fn car -> car.controller == :player end)

    player_car_position = player_car_index_after_finish + 1

    player_car_time_duration = Time.diff(player_car_completion_time, race_start_time, :second)

    %{
      car: player_car_image,
      status: status,
      time: player_car_time_duration,
      position: player_car_position
    }
    |> Result.new()
  end

  @spec update_last_5_results(Result.t(), list(Result.t())) :: list(Result.t())
  def update_last_5_results(new_result = %Result{}, last_5_results)
      when is_list(last_5_results) do
    results_count = length(last_5_results)

    cond do
      results_count == 5 ->
        {_, last_4_results} = List.pop_at(last_5_results, 4)
        [new_result] ++ last_4_results

      results_count < 5 ->
        [new_result] ++ last_5_results
    end
    |> update_review
  end

  defp update_review(_last_5_results = [last_result = %Result{}]) do
    review =
      cond do
        last_result.status == :crash -> :bad
        last_result.position == 1 -> :first
        true -> :good_start
      end

    [%Result{last_result | review: review}]
  end

  defp update_review(_last_5_results = [last_result = %Result{} | other_results]) do
    [last_but_one_result | _other_results] = other_results

    review =
      cond do
        last_result.status == :crash -> :bad
        last_result.position == 1 -> :first
        last_result.position < last_but_one_result.position -> :improvement
        last_result.position > last_but_one_result.position -> :decline
        last_result.position == last_but_one_result.position -> :same
        last_but_one_result.position == nil -> :improvement
      end

    updated_last_result = %Result{last_result | review: review}
    [updated_last_result] ++ other_results
  end
end
