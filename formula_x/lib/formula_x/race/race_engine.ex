defmodule FormulaX.Race.RaceEngine do
  @moduledoc """
  GenServer module that drives all cars
  """
  use GenServer

  alias FormulaX.Race
  alias FormulaX.Race.Car.Control

  # Car position will be changed every 200 milliseconds
  @timeout 200

  def start(race_after_start = %Race{}, race_live_pid) when is_pid(race_live_pid) do
    initial_state = {race_after_start, race_live_pid}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def update_player_car(race_with_updated_player_car = %Race{}) do
    GenServer.cast(__MODULE__, {:update_player_car, race_with_updated_player_car})
  end

  @impl true
  def init(initial_state = {%Race{}, _race_live_pid}) do
    {:ok, initial_state, @timeout}
  end

  @impl true
  @doc """
  This callback moves all cars forward periodically after the race starts
  """
  def handle_info(:timeout, _state = {race = %Race{}, race_live_pid}) do
    updated_race =
      Control.move_autonomous_cars(race, :forward)
      |> Control.move_player_car(:forward)

    updated_state = {updated_race, race_live_pid}
    Process.send(race_live_pid, {:update_race, updated_race}, [])

    {:noreply, updated_state, @timeout}
  end

  @impl true
  @doc """
  This callback updates the Genserver state with changes in player car position resulting from to live view button / key events
  """
  def handle_cast(
        {:update_player_car, race_with_updated_player_car = %Race{}},
        _old_state = {_race, race_live_pid}
      ) do
    updated_state = {race_with_updated_player_car, race_live_pid}

    Process.send(race_live_pid, {:update_race, race_with_updated_player_car}, [])
    {:noreply, updated_state, @timeout}
  end
end
