defmodule FormulaXWeb.RaceLive do
  @moduledoc """
  Liveview that runs the race
  """
  use FormulaXWeb, :live_view

  alias FormulaX.Race
  alias FormulaX.Race.Car

  def render(assigns) do
    ~H"""
    <div class="race_live">
      <div class="console">
        <div class="screen">
          <div class="tracks">
            <div class="track border-l"></div>
            <div class="track"></div>
            <div class="track"></div>
          </div>
          <.cars cars={@race.cars}/>
        </div>
        <.controls/>
      </div>
    </div>
    """
  end

  defp cars(assigns) do
    ~H"""
    <div class="cars">
      <%= for car <- @cars do %>
        <%= with coordinate_class <- coordinate_class(car) do %>
          <%= cond do %>
            <% car.id <= 5 -> %>
                <img src={"/images/cars/#{car.image}"} class={"absolute #{coordinate_class}"}/>
            <%= #For some strange reason the last car has to be set to relative class so that all cars appear on the screen. %>
            <%= #To be investigated %>
            <% car.id == 6 -> %>
                <img src={"/images/cars/#{car.image}"} class={"relative #{coordinate_class}"}/>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp controls(assigns) do
    ~H"""
    <div class="controls" phx-window-keydown="keydown">
      <a class="top" href="#" phx-click="accelerate"></a>
      <a class="bottom" href="#" phx-click="decelerate"></a>
      <a class="right" href="#" phx-click="move_right"></a>
      <a class="left" href="#" phx-click="move_left"></a>
    </div>
    """
  end

  def mount(_params, %{}, socket) do
    race = Race.initialize()
    {:ok, assign(socket, :race, race)}
  end

  def handle_event("accelerate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("decelerate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("move_right", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("move_left", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "ArrowRight"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => _another_key}, socket) do
    {:noreply, socket}
  end

  defp coordinate_class(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "right-[#{x_position}px] top-[#{y_position}px]"
  end
end
