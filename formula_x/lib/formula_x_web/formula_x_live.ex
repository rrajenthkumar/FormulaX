defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to view and control the racing game
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.CarControls
  alias FormulaX.RaceEngine
  alias FormulaX.Utils
  alias FormulaXWeb.Screen
  alias FormulaXWeb.ConsoleControls

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <ConsoleControls.speed_controls clicked_button={@clicked_button}/>
        <Screen.render race={@race} screen_state={@screen_state} car_selection_index={@car_selection_index} countdown_count={@countdown_count}/>
        <ConsoleControls.direction_controls clicked_button={@clicked_button}/>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket) do
    socket =
      socket
      |> assign(:race, nil)
      |> assign(:screen_state, :switched_off)
      |> assign(:clicked_button, nil)
      |> assign(:car_selection_index, nil)
      |> assign(:countdown_count, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{screen_state: :switched_off}
        }
      ) do
    socket = assign(socket, :screen_state, :startup)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_state: :switched_off
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_state, :startup)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{screen_state: :startup}
        }
      ) do
    socket =
      socket
      |> assign(:screen_state, :car_selection)
      |> assign(:car_selection_index, 0)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_state: :startup
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_state, :car_selection)
      |> assign(:car_selection_index, 0)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    socket = assign(socket, :screen_state, :race_info)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    socket =
      socket
      |> assign(:screen_state, :race_info)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_state: :race_info,
            car_selection_index: player_car_index
          }
        }
      ) do
    race = Race.initialize(player_car_index)

    socket =
      socket
      |> assign(:race, race)
      |> assign(:screen_state, :countdown)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)
    Process.send(self(), {:count_down, _count = 3}, [])

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            screen_state: :race_info,
            car_selection_index: player_car_index
          }
        }
      ) do
    race = Race.initialize(player_car_index)

    socket =
      socket
      |> assign(:race, race)
      |> assign(:screen_state, :countdown)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)
    Process.send(self(), {:count_down, _count = 3}, [])

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_state: :active_race
          }
        }
      ) do
    race
    |> CarControls.change_player_car_speed(:speedup)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %{
          assigns: %{
            race: race,
            screen_state: :active_race
          }
        }
      ) do
    race
    |> CarControls.change_player_car_speed(:speedup)
    |> RaceEngine.update()

    socket = assign(socket, :clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_state: :active_race
          }
        }
      ) do
    race
    |> CarControls.change_player_car_speed(:slowdown)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %{
          assigns: %{
            race: race,
            screen_state: :active_race
          }
        }
      ) do
    race
    |> CarControls.change_player_car_speed(:slowdown)
    |> RaceEngine.update()

    socket = assign(socket, :clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_state: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    car_selection_index = update_car_selection_index(car_selection_index, :next)

    socket = assign(socket, :car_selection_index, car_selection_index)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %{
          assigns: %{
            screen_state: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    car_selection_index = update_car_selection_index(car_selection_index, :next)

    socket =
      socket
      |> assign(:car_selection_index, car_selection_index)
      |> assign(:clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_state: :active_race
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
            screen_state: :active_race
          }
        }
      ) do
    race
    |> CarControls.move_player_car(:right)
    |> RaceEngine.update()

    socket = assign(socket, :clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %{
          assigns: %{
            screen_state: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    car_selection_index = update_car_selection_index(car_selection_index, :previous)

    socket = assign(socket, :car_selection_index, car_selection_index)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %{
          assigns: %{
            screen_state: :car_selection,
            car_selection_index: car_selection_index
          }
        }
      ) do
    car_selection_index = update_car_selection_index(car_selection_index, :previous)

    socket =
      socket
      |> assign(:car_selection_index, car_selection_index)
      |> assign(:clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %{
          assigns: %{
            race: race,
            screen_state: :active_race
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
            screen_state: :active_race
          }
        }
      ) do
    race
    |> CarControls.move_player_car(:left)
    |> RaceEngine.update()

    socket = assign(socket, :clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  # For every other instances of pressing the 4 arrow keys
  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket
      ) do
    socket = assign(socket, :clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket
      ) do
    socket = assign(socket, :clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket
      ) do
    socket = assign(socket, :clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket
      ) do
    socket = assign(socket, :clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

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
  def handle_info(
        {:count_down, count},
        socket = %{assigns: %{race: race = %Race{status: :countdown}, screen_state: :countdown}}
      ) do
    socket =
      if count > 0 do
        updated_count = count - 1
        Process.send_after(self(), {:count_down, updated_count}, 1000)
        assign(socket, :countdown_count, count)
      else
        race = Race.start(race)

        RaceEngine.start(race, self())

        assign(socket, :screen_state, :active_race)
      end

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
        :reset_clicked_button_assign,
        socket
      ) do
    socket = assign(socket, :clicked_button, nil)

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
