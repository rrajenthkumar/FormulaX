defmodule FormulaX.Race.RaceEngine do
  @moduledoc """
  GenServer module that drives all cars
  """
  use GenServer

  alias FormulaX.Race
  alias FormulaX.Race.Car.CarControls

  # Cars  will be moved forward every 200 milliseconds
  @timeout 200

  # API

  def start(race_after_flagoff = %Race{}, race_live_pid) when is_pid(race_live_pid) do
    initial_state = {race_after_flagoff, race_live_pid}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def update(updated_race = %Race{}) do
    GenServer.cast(__MODULE__, {:update, updated_race})
  end

  def stop() do
    GenServer.cast(__MODULE__, :stop)
  end

  # Callbacks

  @impl true
  def init(initial_state = {%Race{}, _race_live_pid}) do
    {:ok, initial_state, @timeout}
  end

  @impl true
  @doc """
  This callback moves all cars forward periodically
  """
  def handle_info(:timeout, _state = {race = %Race{}, race_live_pid}) do
    updated_race =
      race
      |> Controls.move_autonomous_cars_forward()
      |> Controls.move_player_car(:forward)

    Process.send(race_live_pid, {:update_visuals, updated_race}, [])
    updated_state = {updated_race, race_live_pid}
    {:noreply, updated_state, @timeout}
  end

  @impl true
  @doc """
  :update - to update the Genserver state and LiveView based on player interactions
  :stop - to stop the Genserver
  """
  def handle_cast(
        {:update, updated_race = %Race{}},
        _state = {_race, race_live_pid}
      ) do
    Process.send(race_live_pid, {:update_visuals, updated_race}, [])
    updated_state = {updated_race, race_live_pid}
    {:noreply, updated_state, @timeout}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end
end
