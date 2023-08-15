defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview that runs the race
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Background

  def render(assigns) do
    ~H"""
    <div class="race_live" phx-window-keydown="keydown">
      <div class="console">
        <.speed_controls/>
        <div class="screen">
          <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
          <div class="race">
            <div class="tracks">
              <div class="track"></div>
              <div class="track"></div>
              <div class="track"></div>
            </div>
            <.cars cars={@race.cars}/>
          </div>
          <.background images={@race.background.right_side_images} y_position={@race.background.y_position}/>
        </div>
        <.direction_controls/>
      </div>
    </div>
    """
  end

  defp speed_controls(assigns) do
    ~H"""
    <div class="speed_controls">
      <a class="top" href="#" phx-click="move"></a>
      <a class="bottom" href="#" phx-click="stop"></a>
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

  defp cars(assigns) do
    ~H"""
    <div class="cars">
      <%= for car <- @cars do %>
        <img src={"/images/cars/#{car.image}"} style={car_position_style(car)}/>
      <% end %>
    </div>
    """
  end

  defp direction_controls(assigns) do
    ~H"""
    <div class="direction_controls">
      <a class="left" href="#" phx-click="steer_left"></a>
      <a class="right" href="#" phx-click="steer_right"></a>
    </div>
    """
  end

  def mount(_params, %{}, socket) do
    race = Race.initialize()

    {:ok, assign(socket, :race, race)}
  end

  def handle_event("start_race", _params, socket = %{race: race}) do
    race =
      race
      |> Race.start()

    {:ok, assign(socket, :race, race)}
  end

  def handle_event(
        "move",
        _params,
        socket
      ) do
    socket = move_player_car(socket)

    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowUp"},
        socket
      ) do
    socket = move_player_car(socket)

    {:noreply, socket}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    {:noreply, socket}
  end

  def handle_event("steer_right", _params, socket) do
    socket = steer_player_car(socket, :right)
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowRight"}, socket) do
    socket = steer_player_car(socket, :right)
    {:noreply, socket}
  end

  def handle_event("steer_left", _params, socket) do
    socket = steer_player_car(socket, :left)
    {:noreply, socket}
  end

  def handle_event(
        "keydown",
        %{"key" => "ArrowLeft"},
        socket
      ) do
    socket = steer_player_car(socket, :left)
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => _another_key}, socket) do
    {:noreply, socket}
  end

  def handle_event("abort_race", _params, socket = %{race: race}) do
    race = Race.abort(race)

    {:ok, assign(socket, :race, race)}
  end

  def handle_event("complete_race", _params, socket = %{race: race}) do
    race = Race.complete(race)

    {:ok, assign(socket, :race, race)}
  end

  defp move_player_car(
         socket = %{
           assigns: %{
             race: race = %Race{background: background, cars: cars}
           }
         }
       ) do
    _player_car =
      %Car{speed: speed} =
      cars
      |> Car.get_player_car()

    updated_background = Background.move(background, speed)

    updated_race = Race.update(race, updated_background)

    assign(socket, :race, updated_race)
  end

  defp steer_player_car(
         socket = %{
           assigns: %{
             race: race = %Race{cars: cars}
           }
         },
         direction
       )
       when is_atom(direction) do
    updated_player_car =
      cars
      |> Car.get_player_car()
      |> Car.steer(direction)

    case Race.crash?(race, updated_player_car) do
      true ->
        socket

      false ->
        updated_cars = Car.update_cars(cars, updated_player_car)

        updated_race = Race.update(race, updated_cars)

        assign(socket, :race, updated_race)
    end
  end

  defp car_position_style(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "left: #{x_position}px; bottom: #{y_position}px;"
  end

  defp background_position_style(y_position) when is_integer(y_position) do
    "top: #{y_position}px"
  end
end
