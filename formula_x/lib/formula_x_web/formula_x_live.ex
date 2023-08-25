defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to view and control the racing game
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car.CarControls
  alias FormulaX.Race.RaceEngine
  alias FormulaX.Utils
  alias FormulaXWeb.Screen
  alias FormulaXWeb.ConsoleControls

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <ConsoleControls.speed_controls button_clicked={@button_clicked}/>
        <Screen.render race={@race} screen_phase={@screen_phase} car_selection_index={@car_selection_index}/>
        <ConsoleControls.direction_controls button_clicked={@button_clicked}/>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket) do
    socket =
      socket
      |> assign(:race, nil)
      |> assign(:screen_phase, :off)
      |> assign(:button_clicked, nil)
      |> assign(:car_selection_index, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{screen_phase: :off}
        }
      ) do
    socket =
      socket
      |> assign(:screen_phase, :startup)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_phase: :off
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_phase, :startup)
      |> assign(:button_clicked, :green)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{screen_phase: :startup}
        }
      ) do
    socket =
      socket
      |> assign(:screen_phase, :car_selection)
      |> assign(:car_selection_index, 0)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_phase: :startup
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_phase, :car_selection)
      |> assign(:button_clicked, :green)
      |> assign(:car_selection_index, 0)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_phase: :car_selection
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_phase, :race_info)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_phase: :car_selection
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_phase, :race_info)
      |> assign(:button_clicked, :green)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_phase: :race_info
          }
        }
      ) do
    # Player car initialisation function to be updated to use info from car_selection_index!!!
    race = Race.initialize()

    socket =
      socket
      |> assign(:race, race)
      |> assign(:screen_phase, :countdown)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_phase: :race_info
          }
        }
      ) do
    # Player car initialisation function to be updated to use info from car_selection_index!!!
    race = Race.initialize()

    socket =
      socket
      |> assign(:race, race)
      |> assign(:screen_phase, :countdown)
      |> assign(:button_clicked, :green)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race =
      race
      |> CarControls.change_player_car_speed(:speedup)
      |> RaceEngine.update()

    socket =
      socket
      |> assign(:race, race)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race =
      race
      |> CarControls.change_player_car_speed(:speedup)
      |> RaceEngine.update()

    socket =
      socket
      |> assign(:race, race)
      |> assign(:button_clicked, :green)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race =
      race
      |> CarControls.change_player_car_speed(:slowdown)
      |> RaceEngine.update()

    socket =
      socket
      |> assign(:race, race)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race =
      race
      |> CarControls.change_player_car_speed(:slowdown)
      |> RaceEngine.update()

    socket =
      socket
      |> assign(:race, race)
      |> assign(:button_clicked, :red)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_phase: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    updated_car_selection_index = update_car_selection_index(car_selection_index, :next)

    socket =
      socket
      |> assign(:car_selection_index, updated_car_selection_index)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %{
          assigns: %{
            screen_phase: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    updated_car_selection_index = update_car_selection_index(car_selection_index, :next)

    socket =
      socket
      |> assign(:button_clicked, :blue)
      |> assign(:car_selection_index, updated_car_selection_index)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race
    |> CarControls.move_player_car(:right)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race
    |> CarControls.move_player_car(:right)
    |> RaceEngine.update()
    |> assign(:button_clicked, :blue)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_phase: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    updated_car_selection_index = update_car_selection_index(car_selection_index, :previous)

    socket =
      socket
      |> assign(:car_selection_index, updated_car_selection_index)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %{
          assigns: %{
            screen_phase: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    updated_car_selection_index = update_car_selection_index(car_selection_index, :previous)

    socket =
      socket
      |> assign(:button_clicked, :yellow)
      |> assign(:car_selection_index, updated_car_selection_index)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race
    |> CarControls.move_player_car(:left)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %{
          assigns: %{
            race: race,
            screen_phase: :active_race
          }
        }
      ) do
    race
    |> CarControls.move_player_car(:left)
    |> RaceEngine.update()
    |> assign(:button_clicked, :yellow)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  # For every other instances of pressing the 4 arrow keys
  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket
      ) do
    socket = assign(socket, :button_clicked, :green)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket
      ) do
    socket = assign(socket, :button_clicked, :red)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket
      ) do
    socket = assign(socket, :button_clicked, :yellow)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket
      ) do
    socket = assign(socket, :button_clicked, :blue)

    Process.send_after(self(), :reset_button_clicked_assign, 250)

    {:noreply, socket}
  end

  # When pressing any other key
  def handle_event(
        "keydown",
        %{"key" => _any_other_key},
        socket
      ) do
    {:noreply, socket}
  end

  # For every other instances of clicking the 4 colour buttons
  def handle_event(
        "green_button_clicked",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  # This will be triggered by countdown screen
  def handle_info(
        :start_race,
        socket = %{assigns: %{race: race = %Race{status: :countdown}, screen_phase: :countdown}}
      ) do
    updated_race = Race.start(race)

    socket =
      socket
      |> assign(:race, updated_race)
      |> assign(:screen_phase, :active_race)

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

  def handle_info(
        :reset_button_clicked_assign,
        socket
      ) do
    socket = assign(socket, :button_clicked, nil)

    {:noreply, socket}
  end

  @spec update_car_selection_index(integer(), :previous | :next) ::
          integer()

  defp update_car_selection_index(
         car_selection_index,
         _action = :next
       )
       when is_integer(car_selection_index) do
    case car_selection_index - maximum_car_selection_index() do
      0 -> 0
      _ -> car_selection_index + 1
    end
  end

  defp update_car_selection_index(
         car_selection_index,
         _action = :previous
       )
       when is_integer(car_selection_index) do
    case car_selection_index do
      0 -> maximum_car_selection_index()
      _ -> car_selection_index - 1
    end
  end

  defp maximum_car_selection_index() do
    number_of_cars =
      "cars"
      |> Utils.get_images()
      |> Enum.count()

    number_of_cars - 1
  end
end
