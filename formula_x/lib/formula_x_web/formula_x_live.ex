defmodule FormulaXWeb.RaceLive do
  use FormulaXWeb, :live_view

  alias FormulaXWeb.CarImageGenerator

  def render(assigns) do
    ~H"""
    <div class="race_live">
      <div class="console">
        <div class="screen">
          <div class="road">
            <div class="track border-l"></div>
            <div class="track"></div>
            <div class="track"></div>
          </div>
          <.cars cars={@cars}/>
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
end
