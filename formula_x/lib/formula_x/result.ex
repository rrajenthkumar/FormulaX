defmodule FormulaX.Result do
  @moduledoc """
  Module used to generate results at the end of a race
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @type status :: :crash | :completed

  @typedoc "Result struct"
  typedstruct do
    field(:car, Car.image(), enforce: true)
    field(:status, status(), enforce: true)
    field(:time, Time.t(), default: nil)
    field(:position, integer(), default: nil)
    field(:emoji, String.t(), default: nil)
  end

  @spec new(map()) :: Result.t()
  def new(attrs) when is_map(attrs) do
    struct!(Result, attrs)
  end

  @spec get_player_car_result(Race.t()) :: Result.t()
  def get_player_car_result(%Race{
        player_car: %Car{image: image, controller: :player},
        status: status = :crash
      }) do
    %{
      car: image,
      status: status
    }
    |> Result.new()
  end

  def get_player_car_result(%Race{
        player_car:
          player_car = %Car{
            completion_time: player_car_completion_time,
            image: image,
            controller: :player
          },
        autonomous_cars: autonomous_cars,
        start_time: race_start_time,
        status: status = :completed
      }) do
    all_cars = autonomous_cars ++ [player_car]

    player_car_index_after_sorting_by_completion_time =
      all_cars
      |> Enum.reject(fn car -> is_nil(car.completion_time) end)
      |> Enum.sort_by(& &1.completion_time, Time)
      |> Enum.find_index(fn car -> car.controller == :player end)

    finishing_position = player_car_index_after_sorting_by_completion_time + 1

    race_time_duration = Time.diff(player_car_completion_time, race_start_time, :second)

    %{
      car: image,
      status: status,
      time: race_time_duration,
      position: finishing_position
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
    |> add_emoji
  end

  @spec add_emoji(list(Result.t())) :: list(Result.t())
  # Case when the player has played only one race and so there is only one available result
  defp add_emoji(_last_5_results = [result = %Result{status: status, position: position}]) do
    emoji =
      cond do
        status == :crash -> "&#128555"
        position == 1 -> "&#127942"
        true -> "&#128079"
      end

    [%Result{result | emoji: emoji}]
  end

  defp add_emoji(
         _last_5_results = [
           last_result = %Result{status: last_result_status, position: last_result_position}
           | other_4_results
         ]
       ) do
    [%Result{position: last_but_one_result_position} | _remaining_results] = other_4_results

    emoji =
      cond do
        last_result_status == :crash -> "&#128555"
        last_result_position == 1 -> "&#127942"
        last_result_position < last_but_one_result_position -> "&#8679"
        last_result_position > last_but_one_result_position -> "&#8681"
        last_result_position == last_but_one_result_position -> "&#128528"
        last_but_one_result_position == nil -> "&#8679"
      end

    updated_last_result = %Result{last_result | emoji: emoji}
    [updated_last_result] ++ other_4_results
  end
end
