defmodule FormulaXWeb.RaceLive.Screen do
  use Phoenix.Component
  use Phoenix.HTML

  alias FormulaX.Parameters
  alias FormulaX.Race
  alias FormulaX.Race.Car
  alias FormulaX.Race.Obstacle
  alias FormulaX.Race.SpeedBoost
  alias FormulaX.Utils

  @car_length Parameters.car_length()

  def render(assigns = %{screen_state: :switched_off}) do
    ~H"""
    <div class="screen switched_off_screen">
    </div>
    """
  end

  def render(assigns = %{screen_state: :startup}) do
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

  def render(assigns = %{screen_state: :car_selection}) do
    ~H"""
    <div class="screen car_selection_screen">
      <div class="body">
        <%= with car <- get_car_image(@car_selection_index) do %>
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

  def render(assigns = %{screen_state: :race_info}) do
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

  def render(assigns = %{screen_state: :race}) do
    ~H"""
    <div class="screen race_screen">
      <.race_setup race={@race}/>
      <%= if @countdown_count do %>
        <div class="countdown">
          <%= @countdown_count %>
        </div>
      <% end %>
    </div>
    """
  end

  def render(assigns = %{screen_state: :crash}) do
    ~H"""
    <div class="screen crash_screen">
      <.race_setup race={@race}/>
      <div class="crash_info">
        <div class="body">
          <p>GAME OVER</p>
        </div>
        <div class="footer">
          <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to start a new race</p>
          <p>Press <span class="red">Red</span> button or <span class="arrow">&#8681</span> key to switch the console off</p>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :result}) do
    ~H"""
    <div class="screen result_screen">
      <.race_setup race={@race}/>
      <div class="result">
        <div class="body">
          <table>
            <tr class="title_row">
              <th></th>
              <th>Result</th>
              <th>Position</th>
              <th>Time</th>
              <th></th>
            </tr>
            <%= for result <- @last_5_results do%>
              <tr>
                <td><img src={"/images/cars/#{result.car}"}/></td>
                <td><%= result.status%></td>
                <td><%= result.position%></td>
                <td><%= "#{result.time} s"%></td>
                <td class={review_class(result.review)}><%= show_review_icon(result.review) |> raw %></td>
              </tr>
            <% end %>
          </table>
        </div>
        <div class="footer">
          <p>Press <span class="green">Green</span> button or <span class="arrow">&#8679</span> key to start a new race</p>
          <p>Press <span class="red">Red</span> button or <span class="arrow">&#8681</span> key to switch the console off</p>
        </div>
      </div>
    </div>
    """
  end

  defp race_setup(assigns) do
    ~H"""
    <.background images={@race.background.left_side_images} y_position={@race.background.y_position}/>
    <div class="race">
      <.lanes/>
      <.cars status={@race.status} player_car={@race.player_car} autonomous_cars={@race.autonomous_cars}/>
      <.obstacles race={@race}/>
      <.speed_boosts race={@race}/>
      <.finish_line race={@race}/>
    </div>
    <.background images={@race.background.right_side_images} y_position={@race.background.y_position}/>
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
      <img class="car" src={"/images/cars/#{@player_car.image}"} style={car_position_style(@player_car)}/>
      <%=if @status == :crash do %>
        <img class="bang" src={"/images/misc/bang.png"} style={crash_illustration_position_style(@player_car)}>
      <% end %>
      <%= for autonomous_car = %Car{image: autonomous_car_image} <- @autonomous_cars do %>
        <img class="car" src={"/images/cars/#{autonomous_car_image}"} style={car_position_style(autonomous_car)}/>
      <% end %>
    </div>
    """
  end

  defp obstacles(assigns) do
    ~H"""
    <div class="obstacles">
      <%= for obstacle <- @race.obstacles do %>
        <div class="obstacle" style={stationary_item_position_style(obstacle, @race)}>
          <.tires />
        </div>
      <% end %>
    </div>
    """
  end

  defp tires(assigns) do
    ~H"""
    <%= for _counter <- 1..6 do %>
      <img src={"/images/misc/tire.png"}/>
    <% end %>
    """
  end

  defp speed_boosts(assigns) do
    ~H"""
    <div class="speed_boosts">
      <%= for speed_boost <- @race.speed_boosts do %>
        <div class="speed_boost" style={stationary_item_position_style(speed_boost, @race)}>
          <img src={"/images/misc/speed_boost.png"} >
        </div>
      <% end %>
    </div>
    """
  end

  defp finish_line(assigns) do
    ~H"""
    <div class="finish_line" style={finish_line_position_style(@race)}>
      <%= for _counter1 <- 1..3 do %>
        <%= for _counter2 <- 1..6 do %>
          <div class="black">
          </div>
          <div class="white">
          </div>
        <% end %>
        <%= for _counter3 <- 1..6 do %>
          <div class="white">
          </div>
          <div class="black">
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @spec car_position_style(Car.t()) :: String.t()
  defp car_position_style(%Car{
         x_position: x_position,
         y_position: y_position
       }) do
    "left: #{x_position}rem; bottom: #{y_position}rem;"
  end

  @spec background_position_style(Parameters.rem()) :: String.t()
  defp background_position_style(y_position) when is_float(y_position) do
    "top: #{y_position}rem"
  end

  @spec crash_illustration_position_style(Car.t()) :: String.t()
  defp crash_illustration_position_style(%Car{
         x_position: player_car_x_position,
         y_position: player_car_y_position,
         controller: :player
       }) do
    "left: #{player_car_x_position - @car_length / 4}rem; bottom: #{player_car_y_position}rem;"
  end

  @spec finish_line_position_style(Race.t()) :: String.t()
  defp finish_line_position_style(%Race{
         player_car: %Car{
           distance_travelled: distance_travelled_by_player_car,
           controller: :player
         },
         distance: race_distance
       }) do
    "bottom: #{race_distance - distance_travelled_by_player_car}rem;"
  end

  @spec stationary_item_position_style(Obstacle.t() | SpeedBoost.t(), Race.t()) :: String.t()
  defp stationary_item_position_style(
         %{x_position: stationary_item_x_position, distance: stationary_item_distance},
         %Race{
           player_car: %Car{
             distance_travelled: distance_travelled_by_player_car,
             controller: :player
           }
         }
       )
       when is_float(stationary_item_x_position) and is_float(stationary_item_distance) do
    stationary_item_y_position = stationary_item_distance - distance_travelled_by_player_car
    "left: #{stationary_item_x_position}rem; bottom: #{stationary_item_y_position}rem;"
  end

  @spec get_car_image(integer()) :: Car.filename()
  defp get_car_image(index) when is_integer(index) do
    "cars"
    |> Utils.get_images()
    |> Enum.at(index)
  end

  @spec show_review_icon(atom()) :: String.t()
  defp show_review_icon(review) when is_atom(review) do
    case review do
      :improvement -> "&#8679"
      :decline -> "&#8681"
      :good_start -> "&#128079"
      :same -> "&#128528"
      :bad -> "&#128555"
      :first -> "&#127942"
    end
  end

  @spec review_class(atom()) :: String.t()
  defp review_class(review) when is_atom(review) do
    case review do
      :improvement ->
        "text-green-700"

      :decline ->
        "text-red-700"

      _ ->
        ""
    end
  end
end
