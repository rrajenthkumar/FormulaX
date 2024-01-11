defmodule FormulaXWeb.RaceLive.ConsoleControls do
  use Phoenix.Component

  def speed_controls(assigns) do
    ~H"""
    <div class="speed_controls">
      <a class="top" href="#" phx-click="green_button_clicked">
        <%= with animation_class <- if @screen_state == :switched_off, do: "flickering_button", else: get_button_animation_class(@clicked_button) do %>
          <span class={animation_class}></span>
        <% end %>
      </a>
      <a class="bottom" href="#" phx-click="red_button_clicked">
        <span class={get_button_animation_class(@clicked_button)}></span>
      </a>
    </div>
    """
  end

  def direction_controls(assigns) do
    ~H"""
    <div class="direction_controls">
      <a class="left" href="#" phx-click="yellow_button_clicked">
        <span class={get_button_animation_class(@clicked_button)}></span>
      </a>
      <a class="right" href="#" phx-click="blue_button_clicked">
        <span class={get_button_animation_class(@clicked_button)}></span>
      </a>
    </div>
    """
  end

  @spec get_button_animation_class(:green | :red | :yellow | :blue) :: String.t()
  defp get_button_animation_class(_clicked_button = :green) do
    "green_button_clicked"
  end

  defp get_button_animation_class(_clicked_button = :red) do
    "red_button_clicked"
  end

  defp get_button_animation_class(__clicked_button = :yellow) do
    "yellow_button_clicked"
  end

  defp get_button_animation_class(_clicked_button = :blue) do
    "blue_button_clicked"
  end

  defp get_button_animation_class(_clicked_button) do
    ""
  end
end
