defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to view and control the racing game
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car.Controls
  alias FormulaX.Race.RaceEngine
  alias FormulaXWeb.Screen
  alias FormulaX.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <.speed_controls/>
        <Screen.render phase={@phase} race={@race} car_selection_tuple={@car_selection_tuple}/>
        <.direction_controls/>
      </div>
    </div>
    """
  end

  defp speed_controls(assigns) do
    ~H"""
    <div class="speed_controls">
      <a class="top" href="#" phx-click="green_button_clicked"></a>
      <a class="bottom" href="#" phx-click="red_button_clicked"></a>
    </div>
    """
  end

  defp direction_controls(assigns) do
    ~H"""
    <div class="direction_controls">
      <a class="left" href="#" phx-click="yellow_button_clicked"></a>
      <a class="right" href="#" phx-click="blue_button_clicked"></a>
    </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket) do
    socket =
      socket
      |> assign(:car_selection_tuple, nil)
      |> assign(:race, nil)
      |> assign(:phase, :startup)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{phase: :startup}
        }
      ) do
    car_selection_tuple = initialise_car_selection_tuple()

    socket =
      socket
      |> assign(:car_selection_tuple, car_selection_tuple)
      |> assign(:phase, :car_selection)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            phase: :startup
          }
        }
      ) do
    car_selection_tuple = initialise_car_selection_tuple()

    socket =
      socket
      |> assign(:car_selection_tuple, car_selection_tuple)
      |> assign(:phase, :car_selection)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            phase: :car_selection
          }
        }
      ) do
    socket = assign(socket, :phase, :race_info)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            phase: :car_selection
          }
        }
      ) do
    socket = assign(socket, :phase, :race_info)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            phase: :race_info
          }
        }
      ) do
    # Player car initialisation function to be updated to use info from car_selection_tuple!!!
    race = Race.initialize()

    socket =
      socket
      |> assign(:race, race)
      |> assign(:phase, :countdown)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            phase: :race_info
          }
        }
      ) do
    # Player car initialisation function to be updated to use info from car_selection_tuple!!!
    race = Race.initialize()

    socket =
      socket
      |> assign(:race, race)
      |> assign(:phase, :countdown)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:speedup)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:speedup)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:slowdown)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.change_player_car_speed(:slowdown)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %{
          assigns: %{
            phase: :car_selection,
            car_selection_tuple: car_selection_tuple
          }
        }
      ) do
    updated_car_selection_tuple = update_car_selection_tuple(car_selection_tuple, :next)
    socket = assign(socket, :car_selection_tuple, updated_car_selection_tuple)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %{
          assigns: %{
            phase: :car_selection,
            car_selection_tuple: car_selection_tuple
          }
        }
      ) do
    updated_car_selection_tuple = update_car_selection_tuple(car_selection_tuple, :next)
    socket = assign(socket, :car_selection_tuple, updated_car_selection_tuple)

    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:right)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:right)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %{
          assigns: %{
            phase: :car_selection,
            car_selection_tuple: car_selection_tuple
          }
        }
      ) do
    updated_car_selection_tuple = update_car_selection_tuple(car_selection_tuple, :previous)
    socket = assign(socket, :car_selection_tuple, updated_car_selection_tuple)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %{
          assigns: %{
            phase: :car_selection,
            car_selection_tuple: car_selection_tuple
          }
        }
      ) do
    updated_car_selection_tuple = update_car_selection_tuple(car_selection_tuple, :previous)
    socket = assign(socket, :car_selection_tuple, updated_car_selection_tuple)

    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:left)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %{
          assigns: %{
            race: race,
            phase: :active_race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:left)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  # For every other instances and other keys
  def handle_event("keydown", %{"key" => _key}, socket) do
    {:noreply, socket}
  end

  @impl true
  # This will be triggered by countdown screen
  def handle_info(
        :start_race,
        socket = %{assigns: %{race: race = %Race{status: :countdown}, phase: :countdown}}
      ) do
    updated_race = Race.start(race)

    socket =
      socket
      |> assign(:race, updated_race)
      |> assign(:phase, :active_race)

    RaceEngine.start(race, self())

    {:noreply, socket}
  end

  def handle_info(
        {:update_visuals, race = %Race{status: status}},
        socket
      ) do
    if status == :aborted do
      RaceEngine.stop()
    end

    socket = assign(socket, :race, race)

    {:noreply, socket}
  end

  defp initialise_car_selection_tuple() do
    all_available_cars = Utils.get_images("cars")

    count = Enum.count(all_available_cars)

    {_current_selection_index = 0, _maximum_index = count - 1, all_available_cars}
  end

  @spec update_car_selection_tuple({integer(), integer(), list(String.t())}, :previous | :next) ::
          {integer(), integer(), list(String.t())}
  defp update_car_selection_tuple(
         _car_selection_tuple = {current_selection_index, maximum_index, all_available_cars},
         _action = :next
       ) do
    updated_current_selection_index =
      case current_selection_index - maximum_index do
        0 -> 0
        _ -> current_selection_index + 1
      end

    {updated_current_selection_index, maximum_index, all_available_cars}
  end

  defp update_car_selection_tuple(
         _car_selection_tuple = {current_selection_index, maximum_index, all_available_cars},
         _action = :previous
       ) do
    updated_current_selection_index =
      case current_selection_index do
        0 -> maximum_index
        _ -> current_selection_index - 1
      end

    {updated_current_selection_index, maximum_index, all_available_cars}
  end
end
