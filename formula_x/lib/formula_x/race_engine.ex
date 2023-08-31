defmodule FormulaX.RaceEngine do
  @moduledoc """
  GenServer module that drives all cars
  """
  use GenServer

  alias FormulaX.Race
  alias FormulaX.CarControl

  # Cars  will be driven forward every 200 milliseconds
  @timeout 200

  # API

  @spec start(Race.t(), pid()) :: {:ok, pid()} | {:error, {:already_started, pid()}}
  def start(race_after_start = %Race{}, race_live_pid) when is_pid(race_live_pid) do
    initial_state = {race_after_start, race_live_pid}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @spec update(Race.t()) :: :ok
  def update(updated_race = %Race{}) do
    GenServer.cast(__MODULE__, {:update, updated_race})
  end

  @spec update(Race.t()) :: :ok
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
  This callback moves all drives cars forward periodically
  """
  def handle_info(:timeout, _state = {race = %Race{}, race_live_pid}) do
    updated_race =
      race
      |> CarControl.drive_autonomous_cars()
      |> CarControl.drive_player_car()

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
