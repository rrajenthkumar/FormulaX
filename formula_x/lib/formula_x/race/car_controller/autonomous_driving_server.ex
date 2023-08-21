defmodule FormulaX.Race.CarController.AutonomousDrivingServer do
  @moduledoc """
  GenServer module that controls computer driven cars
  """
  use GenServer

  alias FormulaX.Race
  alias FormulaX.Race.CarController

  # Cars will be moved every 250 milliseconds
  @timeout 250

  def start(race = %Race{}, race_live_view_pid) do
    state = {race, race_live_view_pid}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state = {%Race{}, _race_live_view_pid}) do
    {:ok, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, _state = {race = %Race{}, race_live_view_pid}) do
    updated_race = CarController.move_computer_controlled_cars(race, :forward)

    updated_state = {updated_race, race_live_view_pid}
    Process.send(race_live_view_pid, {:update_race, updated_race}, [])

    {:noreply, updated_state, @timeout}
  end
end
