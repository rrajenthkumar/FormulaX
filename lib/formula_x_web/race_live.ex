defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to visualize and control the racing game.
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.RaceControl
  alias FormulaX.Result
  alias FormulaX.Utils
  alias FormulaXWeb.RaceLive.ConsoleControls
  alias FormulaXWeb.RaceLive.Screen
  alias Phoenix.LiveView.Socket

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <ConsoleControls.speed_controls screen_state={@screen_state} clicked_button={@clicked_button} />
        <Screen.render
          race={@race}
          screen_state={@screen_state}
          car_selection_index={@car_selection_index}
          countdown_count={@countdown_count}
          last_5_results={@last_5_results}
        />
        <ConsoleControls.direction_controls clicked_button={@clicked_button} />
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket = %Socket{}) do
    updated_socket = initialize_assigns(socket)

    {:ok, updated_socket}
  end

  @impl true
  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{screen_state: :switched_off}
        }
      ) do
    updated_socket = assign(socket, :screen_state, :startup)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            screen_state: :switched_off
          }
        }
      ) do
    updated_socket =
      socket
      |> assign(:screen_state, :startup)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{screen_state: :startup}
        }
      ) do
    updated_socket = assign(socket, :screen_state, :car_selection)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            screen_state: :startup
          }
        }
      ) do
    updated_socket =
      socket
      |> assign(:screen_state, :car_selection)
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{screen_state: :startup}
        }
      ) do
    updated_socket = initialize_switched_off_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            screen_state: :startup
          }
        }
      ) do
    updated_socket =
      socket
      |> initialize_switched_off_screen()
      |> assign(:clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket = initialize_race_info_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket =
      socket
      |> initialize_race_info_screen()
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{screen_state: :car_selection}
        }
      ) do
    updated_socket = initialize_switched_off_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket =
      socket
      |> initialize_switched_off_screen()
      |> assign(:clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket = update_car_selection_index(socket, :next)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket =
      socket
      |> update_car_selection_index(:next)
      |> assign(:clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket = update_car_selection_index(socket, :previous)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %Socket{
          assigns: %{
            screen_state: :car_selection
          }
        }
      ) do
    updated_socket =
      socket
      |> update_car_selection_index(:previous)
      |> assign(:clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :race_info
          }
        }
      ) do
    updated_socket = initialize_race_count_down_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            screen_state: :race_info
          }
        }
      ) do
    updated_socket =
      socket
      |> initialize_race_count_down_screen()
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{screen_state: :race_info}
        }
      ) do
    updated_socket = initialize_switched_off_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            screen_state: :race_info
          }
        }
      ) do
    updated_socket =
      socket
      |> initialize_switched_off_screen()
      |> assign(:clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :crash}
          }
        }
      ) do
    updated_socket = restart_car_selection_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :crash}
          }
        }
      ) do
    updated_socket =
      socket
      |> assign(:clicked_button, :green)
      |> restart_car_selection_screen()

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :ended}
          }
        }
      ) do
    updated_socket = restart_car_selection_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :ended}
          }
        }
      ) do
    updated_socket =
      socket
      |> restart_car_selection_screen()
      |> assign(:clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :crash}
          }
        }
      ) do
    # To avoid screen getting switched off immediately on pressing red button during a crash
    # This might occur when the user tries to unsuccessfully slowdown the car to avoid a crash for example
    Process.send_after(self(), :switch_off_after_crash, 2000)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :crash}
          }
        }
      ) do
    updated_socket = assign(socket, :clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    # To avoid screen getting switched off immediately on pressing red button during a crash
    # This might occur when the user tries to unsuccessfully slowdown the car to avoid a crash for example
    Process.send_after(self(), :switch_off_after_crash, 2000)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :ended}
          }
        }
      ) do
    updated_socket = initialize_switched_off_screen(socket)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            screen_state: :race,
            race: %Race{status: :ended}
          }
        }
      ) do
    updated_socket =
      socket
      |> initialize_switched_off_screen()
      |> assign(:clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.change_player_car_speed(race, :speedup)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.change_player_car_speed(race, :speedup)

    updated_socket = assign(socket, :clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.change_player_car_speed(race, :slowdown)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.change_player_car_speed(race, :slowdown)

    updated_socket = assign(socket, :clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.steer_player_car(race, :right)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.steer_player_car(race, :right)

    updated_socket = assign(socket, :clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.steer_player_car(race, :left)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.steer_player_car(race, :left)

    updated_socket = assign(socket, :clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "race_screen_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.pause_race(race)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => " "},
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :ongoing},
            screen_state: :race
          }
        }
      ) do
    RaceControl.pause_race(race)

    {:noreply, socket}
  end

  def handle_event(
        "race_screen_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    RaceControl.unpause_race(race)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => " "},
        socket = %Socket{
          assigns: %{
            race: race = %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    RaceControl.unpause_race(race)

    {:noreply, socket}
  end

  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    updated_socket = assign(socket, :clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    updated_socket = assign(socket, :clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    updated_socket = assign(socket, :clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %Socket{
          assigns: %{
            race: %Race{status: :paused},
            screen_state: :race
          }
        }
      ) do
    updated_socket = assign(socket, :clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  # For every other instances of pressing the 4 arrow keys
  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket = %Socket{}
      ) do
    updated_socket = assign(socket, :clicked_button, :green)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowDown"},
        socket = %Socket{}
      ) do
    updated_socket = assign(socket, :clicked_button, :red)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket = %Socket{}
      ) do
    updated_socket = assign(socket, :clicked_button, :yellow)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowRight"},
        socket = %Socket{}
      ) do
    updated_socket = assign(socket, :clicked_button, :blue)

    Process.send_after(self(), :reset_clicked_button_assign, 250)

    {:noreply, updated_socket}
  end

  # When pressing any other key
  def handle_event(
        "keydown",
        %{"key" => _any_other_key},
        socket = %Socket{}
      ) do
    {:noreply, socket}
  end

  # For every other instances of clicking the 4 colour buttons
  def handle_event(
        "green_button_clicked",
        _params,
        socket = %Socket{}
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "red_button_clicked",
        _params,
        socket = %Socket{}
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "yellow_button_clicked",
        _params,
        socket = %Socket{}
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "blue_button_clicked",
        _params,
        socket = %Socket{}
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:count_down, count},
        socket = %Socket{
          assigns: %{race: race = %Race{status: :countdown}, screen_state: :race}
        }
      )
      when is_integer(count) do
    updated_socket =
      if count > 0 do
        updated_count = count - 1
        Process.send_after(self(), {:count_down, updated_count}, 1000)

        assign(socket, :countdown_count, count)
      else
        race_liveview_pid = self()
        RaceControl.start_race(race, race_liveview_pid)

        assign(socket, :countdown_count, nil)
      end

    {:noreply, updated_socket}
  end

  def handle_info(
        {:update_visuals,
         race = %Race{
           player_car: %Car{speed_boost_enabled?: speed_boost_enabled?},
           status: status
         }},
        socket = %Socket{}
      )
      when is_atom(status) do
    updated_socket =
      cond do
        status === :crash or status === :ended ->
          socket
          |> assign(:race, race)
          |> update_results()

        status === :ongoing and speed_boost_enabled? ->
          Process.send_after(self(), :disable_speed_boost, 5000)

          assign(socket, :race, race)

        true ->
          assign(socket, :race, race)
      end

    {:noreply, updated_socket}
  end

  def handle_info(
        :disable_speed_boost,
        socket = %Socket{
          assigns: %{
            race:
              race = %Race{
                player_car: %Car{speed_boost_enabled?: speed_boost_enabled?},
                status: status
              },
            screen_state: :race
          }
        }
      ) do
    if status === :ongoing and speed_boost_enabled? do
      RaceControl.disable_speed_boost(race)
    end

    {:noreply, socket}
  end

  # When 'screen_state' is not :race
  def handle_info(
        :disable_speed_boost,
        socket = %Socket{}
      ) do
    {:noreply, socket}
  end

  def handle_info(
        :reset_clicked_button_assign,
        socket = %Socket{}
      ) do
    updated_socket = assign(socket, :clicked_button, nil)

    {:noreply, updated_socket}
  end

  def handle_info(:switch_off_after_crash, socket) do
    updated_socket = initialize_switched_off_screen(socket)
    {:noreply, updated_socket}
  end

  @spec initialize_assigns(Socket.t()) :: Socket.t()
  defp initialize_assigns(socket = %Socket{}) do
    socket
    |> assign(:race, nil)
    |> assign(:screen_state, :switched_off)
    |> assign(:clicked_button, nil)
    |> assign(:car_selection_index, 0)
    |> assign(:countdown_count, nil)
    |> assign(:last_5_results, [])
  end

  @spec update_car_selection_index(Socket.t(), :previous | :next) ::
          Socket.t()
  defp update_car_selection_index(
         socket = %Socket{assigns: %{car_selection_index: car_selection_index}},
         _action = :next
       )
       when is_integer(car_selection_index) do
    updated_car_selection_index =
      if car_selection_index - maximum_car_selection_index() === 0 do
        0
      else
        car_selection_index + 1
      end

    assign(socket, :car_selection_index, updated_car_selection_index)
  end

  defp update_car_selection_index(
         socket = %Socket{assigns: %{car_selection_index: car_selection_index}},
         _action = :previous
       )
       when is_integer(car_selection_index) do
    updated_car_selection_index =
      if car_selection_index === 0 do
        maximum_car_selection_index()
      else
        car_selection_index - 1
      end

    assign(socket, :car_selection_index, updated_car_selection_index)
  end

  @spec maximum_car_selection_index() :: integer()
  defp maximum_car_selection_index do
    number_of_cars =
      "cars"
      |> Utils.get_filenames_of_images!()
      |> Enum.count()

    number_of_cars - 1
  end

  @spec initialize_race_info_screen(Socket.t()) :: Socket.t()
  defp initialize_race_info_screen(socket = %Socket{assigns: %{last_5_results: last_5_results}})
       when is_list(last_5_results) do
    # To ensure that race info screen is showed only once after the console is switched ON
    if last_5_results === [] do
      assign(socket, :screen_state, :race_info)
    else
      initialize_race_count_down_screen(socket)
    end
  end

  @spec initialize_race_count_down_screen(Socket.t()) :: Socket.t()
  defp initialize_race_count_down_screen(
         socket = %Socket{assigns: %{car_selection_index: player_car_image_index}}
       )
       when is_integer(player_car_image_index) do
    race = Race.initialize(player_car_image_index)

    updated_socket =
      socket
      |> assign(:race, race)
      |> assign(:screen_state, :race)

    Process.send_after(self(), {:count_down, _count = 3}, 500)

    updated_socket
  end

  @spec update_results(Socket.t()) :: Socket.t()
  defp update_results(
         socket = %Socket{
           assigns: %{
             race: race = %Race{},
             last_5_results: last_5_results
           }
         }
       )
       when is_list(last_5_results) do
    last_5_results =
      race
      |> Result.get_player_car_result()
      |> Result.update_last_5_results(last_5_results)

    socket
    |> assign(:last_5_results, last_5_results)
  end

  @spec restart_car_selection_screen(Socket.t()) :: Socket.t()
  defp restart_car_selection_screen(socket = %Socket{}) do
    socket
    |> assign(:screen_state, :car_selection)
    |> assign(:race, nil)
    |> assign(:countdown_count, nil)
  end

  @spec initialize_switched_off_screen(Socket.t()) :: Socket.t()
  defp initialize_switched_off_screen(socket = %Socket{}) do
    socket
    |> assign(:screen_state, :switched_off)
    |> assign(:race, nil)
    |> assign(:car_selection_index, 0)
    |> assign(:countdown_count, nil)
    |> assign(:last_5_results, [])
  end
end
