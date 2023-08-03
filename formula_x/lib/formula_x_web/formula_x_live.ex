defmodule FormulaXWeb.RaceLive do
  use FormulaXWeb, :live_view

  alias FormulaXWeb.CarImageGenerator

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
          <.cars cars={@cars}/>
        </div>
        <div class="controls" phx-window-keydown="keydown">
          <a class="top" href="#" phx-click="accelerate"></a>
          <a class="bottom" href="#" phx-click="decelerate"></a>
          <a class="right" href="#" phx-click="move_right"></a>
          <a class="left" href="#" phx-click="move_left"></a>
        </div>
      </div>
    </div>
    """
  end

  defp cars(assigns) do
    ~H"""
    <div class="cars">
      <%= for car <- @cars do %>
        <img src={car.image_source} class={"w-14 inline-block #{car.position_class}"}/>
      <% end %>
    </div>
    """
  end

  def mount(_params, %{}, socket) do
    {:ok, assign(socket, :cars, CarImageGenerator.cars())}
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
end
