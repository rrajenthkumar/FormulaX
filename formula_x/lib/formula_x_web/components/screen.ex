defmodule FormulaXWeb.Screen do
  use Phoenix.Component

  alias FormulaX.Race.Car
  alias FormulaX.Utils

  def render(assigns = %{phase: :off}) do
    ~H"""
    <div class="screen off_screen">
    </div>
    """
  end

  def render(assigns = %{phase: :startup}) do
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
      <div class="footer">
        <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to proceed</p>
      </div>
    </div>
    """
  end

  def render(assigns = %{phase: :car_selection}) do
    ~H"""
    <div class="screen car_selection_screen">
      <div class="body">
        <%= with car <- Utils.get_images("cars") |> Enum.at(@car_selection_index) do %>
          <img src={"/images/cars/#{car}"}/>
        <% end %>
      </div>
      <div class="footer">
        <p>Browse cars using <span class="yellow">Yellow</span> and <span class="blue">Blue</span> buttons or using <span class="arrow">&#8678</span> and <span class="arrow">&#8680</span> keys</p>
        <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to select your car and proceed</p>
      </div>
    </div>
    """
  end

  def render(assigns = %{phase: :race_info}) do
    ~H"""
    <div class="screen race_info_screen">
      <div class="body">
        <h1 class="title">Instructions</h1>
        <ul class="instructions_list">
          <li>
            <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to start car</p>
          </li>
          <li>
            <p>After car starts use the <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to switch speeds in the increasing order of rest, low, moderate and high</p>
          </li>
          <li>
            <p>Use the <span class="red">Red</span> button or <span class="arrow">&#8681</span> key to switch speeds in the decreasing order of high, moderate, low, rest</p>
          </li>
          <li>
            <p>Use the <span class="yellow">Yellow</span> button or <span class="arrow">&#8678</span> key to move left</p>
          </li>
          <li>
            <p>Use the <span class="blue">Blue</span> button or <span class="arrow">&#8680</span> key to move right</p>
          </li>
          <li>
            <p>Try to navigate the lanes and finish the race</p>
          </li>
          <li>
            <p>Whoever finishes the race in the shortest time wins the race!!!</p>
          </li>
        </ul>
      </div>
      <div class="footer">
        <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to proceed</p>
      </div>
    </div>
    """
  end

  def render(assigns = %{phase: :countdown}) do
    ~H"""
    <%= # Insert countdown screen in this template and once countdown is over send a message ":start_race" to live view. This template should have race initial visual along with countdown div" %>
    <div class="screen countdown_screen">
      <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
      <div class="race">
        <.lanes/>
        <.cars cars={@race.cars}/>
      </div>
      <.background images={@race.background.right_side_images} y_position={@race.background.y_position}/>
    </div>
    """
  end

  def render(assigns = %{phase: :active_race}) do
    ~H"""
    <div class="screen active_race_screen">
      <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
      <div class="race">
        <.lanes/>
        <.cars cars={@race.cars}/>
      </div>
      <.background images={@race.background.right_side_images} y_position={@race.background.y_position}/>
    </div>
    """
  end

  def render(assigns = %{phase: :result}) do
    ~H"""
    <div class="screen result_screen">
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
