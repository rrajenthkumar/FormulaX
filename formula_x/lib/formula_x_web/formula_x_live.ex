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
            <div class="lanes">
              <div class="lane"></div>
              <div class="lane"></div>
              <div class="lane"></div>
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
             race: race = %Race{background: background}
           }
         }
       ) do
    _player_car = %Car{speed: speed} = Race.get_player_car(race)

    # Background is moved in opposite direction to simulate car movement
    updated_background = Background.move(background, speed)
    updated_race = Race.update_background(race, updated_background)

    assign(socket, :race, updated_race)
  end

  defp steer_player_car(
         socket = %{
           assigns: %{
             race: race = %Race{}
           }
         },
         direction
       )
       when is_atom(direction) do
    player_car = Race.get_player_car(race)

    case Race.crash?(race, player_car.car_id, direction) do
      true ->
        IO.puts("*******************CRASH!!!*********************")
        socket

      false ->
        updated_player_car = Car.steer(player_car, direction)

        updated_race = Race.update_cars(race, updated_player_car)

        assign(socket, :race, updated_race)
    end
  end

  @spec car_position_style(Car.t()) :: String.t()
  defp car_position_style(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "left: #{x_position}px; bottom: #{y_position}px;"
  end

  @spec car_position_style(integer()) :: String.t()
  defp background_position_style(y_position) when is_integer(y_position) do
    "top: #{y_position}px"
  end
end
