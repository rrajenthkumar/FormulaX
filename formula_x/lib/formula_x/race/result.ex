defmodule FormulaX.Race.Result do
  @moduledoc """
  **Result context**
  """
  use TypedStruct

  alias __MODULE__
  alias FormulaX.Race
  alias FormulaX.Race.Car

  @type status :: :crash | :completed

  @typedoc "Result struct"
  typedstruct do
    field(:car, Car.image(), enforce: true)
    field(:status, status(), default: :crash)
    field(:duration, Time.t(), default: nil)
    field(:position, integer(), default: nil)
  end

  @spec new(map()) :: Result.t()
  def new(attrs) when is_map(attrs) do
    struct!(Result, attrs)
  end

  @spec get_player_car_result(Race.t()) :: Result.t()
  def get_player_car_result(
        race = %Race{cars: cars, start_time: race_start_time, status: race_status}
      ) do
    %Car{completion_time: player_car_completion_time, image: player_car_image} =
      Race.get_player_car(race)

    player_car_index_after_finish =
      cars
      |> Enum.reject(fn car -> is_nil(car.completion_time) end)
      |> Enum.sort_by(& &1.completion_time, Time)
      |> Enum.find_index(fn car -> car.controller == :player end)

    player_car_position = player_car_index_after_finish + 1

    player_car_duration = Time.diff(player_car_completion_time, race_start_time, :second)

    %{
      car: player_car_image,
      status: race_status,
      duration: player_car_duration,
      position: player_car_position
    }
    |> Result.new()
  end

  @spec update_last_5_results(list(Result.t()), list(Result.t())) :: list(Result.t())
  def update_last_5_results(new_result, last_5_results) do
    results_count = length(last_5_results)

    cond do
      results_count == 5 ->
        {_, results} = List.pop_at(last_5_results, 4)
        [new_result] ++ results

      results_count < 5 ->
        [new_result] ++ last_5_results
    end
  end
end
