defmodule FormulaX.RaceEngine do
  @moduledoc """
  Module that drives all cars forward, taking player interations into account, using GenServer.
  """
  use GenServer

  alias FormulaX.CarControl
  alias FormulaX.Race

  @timeout 200

  # API
  @spec start(Race.t(), pid()) :: {:ok, pid()} | {:error, {:already_started, pid()}}
  def start(started_race = %Race{status: :ongoing}, race_liveview_pid)
      when is_pid(race_liveview_pid) do
    initial_state = {started_race, race_liveview_pid}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @spec update(Race.t()) :: :ok
  def update(updated_race = %Race{}) do
    GenServer.cast(__MODULE__, {:update, updated_race})
  end

  # Callbacks
  @impl true
  def init(initial_state = {%Race{status: :ongoing}, race_liveview_pid})
      when is_pid(race_liveview_pid) do
    {:ok, initial_state, @timeout}
  end

  @impl true
  @doc """
  This callback is called every timeout period of 200 milliseconds.

  1. When the race status is :paused, the Genserver keeps looping without any action.
  2. When the race status is :crash or :ended, the Genserver is stopped.
  3. When the race status is :ongoing, it drives all cars forward and updates the Race LiveView.
  """
  def handle_info(:timeout, state = {%Race{status: :paused}, race_liveview_pid})
      when is_pid(race_liveview_pid) do
    {:noreply, state, @timeout}
  end

  def handle_info(:timeout, state = {%Race{status: status}, race_liveview_pid})
      when status in [:crash, :ended] and is_pid(race_liveview_pid) do
    {:stop, :normal, state}
  end

  def handle_info(:timeout, _state = {race = %Race{}, race_liveview_pid})
      when is_pid(race_liveview_pid) do
    updated_race =
      race
      # Autonomous cars are driven forward first so that while driving the player car forward we do crash check precisely using the latest Autonomous car positions
      |> CarControl.drive_autonomous_cars()
      |> CarControl.drive_player_car()

    Process.send(race_liveview_pid, {:update_visuals, updated_race}, [])
    updated_state = {updated_race, race_liveview_pid}
    {:noreply, updated_state, @timeout}
  end

  @impl true
  @doc """
  Updates the Genserver state and Race LiveView based on player interactions  like steering,increasing speed, pausing, unpausing
  """
  def handle_cast(
        {:update, updated_race = %Race{}},
        _state = {_current_race = %Race{}, race_liveview_pid}
      )
      when is_pid(race_liveview_pid) do
    Process.send(race_liveview_pid, {:update_visuals, updated_race}, [])
    updated_state = {updated_race, race_liveview_pid}
    {:noreply, updated_state, @timeout}
  end
end
