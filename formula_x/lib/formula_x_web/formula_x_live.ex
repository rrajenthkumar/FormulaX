defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to view and control the racing game
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Car.Controls
  alias FormulaX.Race.RaceEngine
  alias FormulaX.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <.speed_controls/>
        <.screen phase={@phase} race={@race} car_selection_tuple={@car_selection_tuple}/>
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

  defp screen(assigns = %{phase: :startup}) do
    ~H"""
    <div class="screen startup_screen">
      <div class="body">
        <div class="content">
          <div class="text_container">
            <h1><span class="title">Formula</span><span class="title_suffix">X</span></h1>
            <p class="subtitle">Powered by Elixir/Phoenix</p>
            <p class="subtitle">Built by Rajenth</p>
          </div>
        </div>
      </div>
      <div class="footer">Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> to proceed</div>
    </div>
    """
  end

  defp screen(assigns = %{phase: :car_selection}) do
    ~H"""
    <div class="screen car_selection_screen">
      <div class="body">
        <%= with {current_selection_index, _maximum_index, all_available_cars} <- @car_selection_tuple,
                  car                                                         <- Enum.at(all_available_cars, current_selection_index) do %>
          <img src={"/images/cars/#{car}"}/>
        <% end %>
      </div>
      <div class="footer">
      <p>Browse cars using <span class="yellow">Yellow</span> and <span class="blue">Blue</span> buttons or using <span class="arrow">&#8678</span> and <span class="arrow">&#8680</span></p>
      <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> to select your car and proceed</p>
      </div>
    </div>
    """
  end

  defp screen(assigns = %{phase: :race_info}) do
    ~H"""
    <div class="screen">
    </div>
    """
  end

  defp screen(assigns = %{phase: :countdown}) do
    ~H"""
    <div class="screen">
    </div>
    """
  end

  defp screen(assigns = %{phase: :race}) do
    ~H"""
    <div class="screen race_screen">
      <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
        <div class="race">
          <.lanes/>
          <.cars cars={@race.cars}/>
        </div>
      <.background images={@race.background.right_side_images} y_position={@race.background.y_position}/>
    </div>
    """
  end

  defp screen(assigns = %{phase: :result}) do
    ~H"""
    <div class="screen">
    </div>
    """
  end

  defp screen(assigns = %{phase: :off}) do
    ~H"""
    <div class="screen">
    </div>
    """
  end

  defp lanes(assigns) do
    ~H"""
    <div class="lanes">
      <div class="lane"></div>
      <div class="lane"></div>
      <div class="lane"></div>
    </div>
    """
  end

  defp cars(assigns) do
    ~H"""
    <div class="cars">
      <%= for car <- @cars do %>
        <img src={"/images/cars/#{car.image}"} style={car_position_style(car)}/>
      <% end %>
    </div>
    """
  end

  defp background(assigns) do
    ~H"""
    <div class="background" style={background_position_style(@y_position)}>
      <%= for image <- @images do %>
        <div class="image_container">
          <img src={"/images/backgrounds/#{image}"} />
        </div>
      <% end %>
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
    # race =
    #   Race.initialize()
    #   |> Race.start()

    socket =
      socket
      |> assign(:car_selection_tuple, nil)
      |> assign(:race, nil)
      |> assign(:phase, :startup)

    # RaceEngine.start(race, self())

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
            phase: :car_selection,
            car_selection_tuple: {current_selection_index, _maximum_index, all_available_cars}
          }
        }
      ) do
    player_car_image = Enum.at(all_available_cars, current_selection_index)

    socket =
      socket
      |> assign(:player_car_image, player_car_image)
      |> assign(:phase, :race_info)

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
            race: race,
            phase: :race
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
            phase: :race
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
            phase: :race
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
            phase: :race
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
            phase: :race
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
            phase: :race
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
            phase: :race
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
            phase: :race
          }
        }
      ) do
    race
    |> Controls.move_player_car(:left)
    |> RaceEngine.update()

    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => _another_key}, socket) do
    {:noreply, socket}
  end

  @impl true
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

  @spec car_position_style(Car.t()) :: String.t()
  defp car_position_style(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "left: #{x_position}px; bottom: #{y_position}px;"
  end

  @spec background_position_style(Car.y_position()) :: String.t()
  defp background_position_style(y_position) when is_integer(y_position) do
    "top: #{y_position}px"
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
