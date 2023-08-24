defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview to view and control the racing game
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Car.Controls
  alias FormulaX.Race.RaceEngine

  @impl true
  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <.speed_controls/>
        <.screen phase={@phase} race={@race}/>
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
    <div class="screen">
    </div>
    """
  end

  defp screen(assigns = %{phase: :game_controls_info}) do
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
    race =
      Race.initialize()
      |> Race.start()

    RaceEngine.start(race, self())

    socket =
      socket
      |> assign(:phase, :startup)
      |> assign(:race, race)

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
    socket = assign(socket, :phase, :car_selection)

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
end
