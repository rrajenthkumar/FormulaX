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
    <div class="screen switched_off_screen"></div>
    """
  end

  def render(assigns = %{screen_state: :startup}) do
    ~H"""
    <div class="screen startup_screen">
      <audio src="sounds/Carmack_FadeEndm.mp3" type="audio/mp3" autoplay="true" preload="auto">
      </audio>
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
        <.to_proceed_info />
        <.power_off_info />
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :car_selection}) do
    ~H"""
    <div class="screen car_selection_screen">
      <div class="body">
        <%= with car <- get_car_image(@car_selection_index) do %>
          <img src={"/images/cars/#{car}"} />
        <% end %>
      </div>
      <div class="footer">
        <p>
          <span class="yellow">Yellow</span>
          / <span class="blue">Blue</span>
          buttons or <span class="arrow">&#8678</span>
          / <span class="arrow">&#8680</span>
          keys to browse cars
        </p>
        <.to_proceed_info />
        <.power_off_info />
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :race_info}) do
    ~H"""
    <div class="screen race_info_screen">
      <div class="body">
        <h1 class="title">Race controls:</h1>
        <ul class="instructions_list">
          <li>
            <p>
              <span class="green">Green</span>
              button or <span class="arrow">&#8679</span>
              key to switch car speeds in increasing order
            </p>
          </li>
          <li>
            <p>
              <span class="red">Red</span>
              button or <span class="arrow">&#8681</span>
              key to switch car speeds in decreasing order
            </p>
          </li>
          <li>
            <p>
              <span class="yellow">Yellow</span>
              button or <span class="arrow">&#8678</span>
              key to move left
            </p>
          </li>
          <li>
            <p>
              <span class="blue">Blue</span>
              button or <span class="arrow">&#8680</span>
              key to move right
            </p>
          </li>
          <li>
            <p>Click on console screen or press Spacebar to pause / unpause race</p>
          </li>
          <li>
            <p>Key board controls are recommended for Laptop and PC</p>
          </li>
        </ul>
      </div>
      <div class="footer">
        <.to_proceed_info />
        <.power_off_info />
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :race, race: %Race{status: :countdown}}) do
    ~H"""
    <div class="screen race_screen">
      <audio
        src="sounds/mixkit-simple-game-countdown-921.wav"
        type="audio/wav"
        autoplay="true"
        preload="auto"
      >
      </audio>
      <.race_setup race={@race} />
      <div class="count_down_info">
        <span class="countdown">
          <%= @countdown_count %>
        </span>
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :race, race: %Race{status: :ongoing}}) do
    ~H"""
    <div class="screen race_screen race_pause_feature" phx-click="race_screen_clicked">
      <audio
        src="sounds/rally-car-idle-loop-14-32339.mp3"
        type="audio/mp3"
        autoplay="true"
        loop="true"
        preload="auto"
      >
      </audio>
      <.race_setup race={@race} />
    </div>
    """
  end

  def render(assigns = %{screen_state: :race, race: %Race{status: :paused}}) do
    ~H"""
    <div class="screen race_screen race_pause_feature" phx-click="race_screen_clicked">
      <.race_setup race={@race} />
      <div class="pause_info">
        <div class="body">
          <img class="pause_icon" src="/images/icons/pause.png" alt="pause icon" />
        </div>
        <div class="footer">
          <p>Click on console screen or press Spacebar to unpause</p>
        </div>
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :race, race: %Race{status: :crash}}) do
    ~H"""
    <div class="screen race_screen">
      <audio
        src="sounds/mixkit-arcade-fast-game-over-233.wav"
        type="audio/wav"
        autoplay="true"
        preload="auto"
      >
      </audio>
      <.race_setup race={@race} />
      <div class="game_over_info">
        <div class="body">
          <span class="text_part_1">Game</span>&nbsp;<span class="text_part_2">Over</span>
        </div>
        <div class="footer">
          <.new_race_info />
          <.power_off_info />
        </div>
      </div>
    </div>
    """
  end

  def render(assigns = %{screen_state: :race, race: %Race{status: :ended}}) do
    ~H"""
    <div class="screen race_screen">
      <audio
        src="sounds/mixkit-cheering-crowd-loud-whistle-610.wav"
        type="audio/wav"
        autoplay="true"
        preload="auto"
      >
      </audio>
      <.race_setup race={@race} />
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
            <%= for result <- @last_5_results do %>
              <%= with result_time <- if result.time, do: "#{result.time} s", else: "" do %>
                <tr>
                  <td><img src={"/images/cars/#{result.car}"} /></td>
                  <td><%= result.status %></td>
                  <td><%= result.position %></td>
                  <td><%= result_time %></td>
                  <td class={symbol_class(result.symbol)}><%= raw(result.symbol) %></td>
                </tr>
              <% end %>
            <% end %>
          </table>
        </div>
        <div class="footer">
          <.new_race_info />
          <.power_off_info />
        </div>
      </div>
    </div>
    """
  end

  defp race_setup(assigns) do
    ~H"""
    <.background images={@race.background.left_side_images} y_position={@race.background.y_position} />
    <div class="race">
      <%= if @race.status === :crash do %>
        <img
          class="crash_illustration"
          src="/images/misc/bang.png"
          style={crash_illustration_position_style(@race.player_car)}
        />
      <% end %>
      <.lanes />
      <.cars player_car={@race.player_car} autonomous_cars={@race.autonomous_cars} />
      <.obstacles race={@race} />
      <.speed_boosts race={@race} />
      <.finish_line race={@race} />
    </div>
    <.background images={@race.background.right_side_images} y_position={@race.background.y_position} />
    """
  end

  defp background(assigns) do
    ~H"""
    <div class="background" style={background_position_style(@y_position)}>
      <%= for image <- @images do %>
        <img src={"/images/backgrounds/#{image}"} />
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
      <%= with highlight_class <- if @player_car.speed_boost_enabled?, do: "speed_boost_highlight", else: "car_highlight" do %>
        <img
          class={"car player_car #{highlight_class}"}
          src={"/images/cars/#{@player_car.image}"}
          style={car_position_style(@player_car)}
        />
      <% end %>
      <%= for autonomous_car = %Car{image: autonomous_car_image} <- @autonomous_cars do %>
        <img
          class="car autonomous_car"
          src={"/images/cars/#{autonomous_car_image}"}
          style={car_position_style(autonomous_car)}
        />
      <% end %>
    </div>
    """
  end

  defp obstacles(assigns) do
    ~H"""
    <div class="obstacles">
      <%= for obstacle <- @race.obstacles do %>
        <div class="obstacle" style={obstacle_and_speed_boost_position_style(obstacle, @race)}>
          <.tires />
        </div>
      <% end %>
    </div>
    """
  end

  defp tires(assigns) do
    ~H"""
    <%= for _counter <- 1..12 do %>
      <img src="/images/misc/tire.png" />
    <% end %>
    """
  end

  defp speed_boosts(assigns) do
    ~H"""
    <div class="speed_boosts">
      <%= for speed_boost <- @race.speed_boosts do %>
        <div class="speed_boost" style={obstacle_and_speed_boost_position_style(speed_boost, @race)}>
          <img src="/images/misc/speed_boost.png" />
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
          <div class="black"></div>
          <div class="white"></div>
        <% end %>
        <%= for _counter3 <- 1..6 do %>
          <div class="white"></div>
          <div class="black"></div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp to_proceed_info(assigns) do
    ~H"""
    <p><span class="green">Green</span> button or <span class="arrow">&#8679</span> key to proceed</p>
    """
  end

  defp new_race_info(assigns) do
    ~H"""
    <p>
      <span class="green">Green</span> button or <span class="arrow">&#8679</span> key for a new race
    </p>
    """
  end

  defp power_off_info(assigns) do
    ~H"""
    <p><span class="red">Red</span> button or <span class="arrow">&#8681</span> key to switch off</p>
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
           y_position: player_car_y_position,
           controller: :player
         },
         distance: race_distance
       }) do
    "bottom: #{race_distance - (distance_travelled_by_player_car + player_car_y_position)}rem;"
  end

  @spec obstacle_and_speed_boost_position_style(Obstacle.t() | SpeedBoost.t(), Race.t()) ::
          String.t()
  defp obstacle_and_speed_boost_position_style(
         %{
           x_position: obstacle_or_speed_boost_x_position,
           distance: obstacle_or_speed_boost_distance
         },
         %Race{
           player_car: %Car{
             distance_travelled: distance_travelled_by_player_car,
             y_position: player_car_y_position,
             controller: :player
           }
         }
       )
       when is_float(obstacle_or_speed_boost_x_position) and
              is_float(obstacle_or_speed_boost_distance) do
    obstacle_or_speed_boost_y_position =
      obstacle_or_speed_boost_distance -
        (distance_travelled_by_player_car + player_car_y_position)

    "left: #{obstacle_or_speed_boost_x_position}rem; bottom: #{obstacle_or_speed_boost_y_position}rem;"
  end

  @spec get_car_image(integer()) :: Car.filename()
  defp get_car_image(index) when is_integer(index) do
    "cars"
    |> Utils.get_filenames_of_images!()
    |> Enum.at(index)
  end

  @spec symbol_class(String.t()) :: String.t()
  defp symbol_class(symbol) when is_binary(symbol) do
    case symbol do
      "&#8679" ->
        "text-green-700"

      "&#8681" ->
        "text-red-700"

      _ ->
        ""
    end
  end
end
