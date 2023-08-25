defmodule FormulaXWeb.ConsoleControls do
  use Phoenix.Component

  def speed_controls(assigns) do
    ~H"""
    <div class="speed_controls">
      <%= if @button_clicked == :green do %>
        <a class="top" href="#" phx-click="green_button_clicked"><span class="green_button_clicked"></span></a>
      <% else %>
        <a class="top" href="#" phx-click="green_button_clicked"><span></span></a>
      <% end %>
      <%= if @button_clicked == :red do %>
        <a class="bottom" href="#" phx-click="red_button_clicked"><span class="red_button_clicked"></span></a>
      <% else %>
        <a class="bottom" href="#" phx-click="red_button_clicked"><span></span></a>
      <% end %>
    </div>
    """
  end

  def direction_controls(assigns) do
    ~H"""
    <div class="direction_controls">
      <%= if @button_clicked == :yellow do %>
        <a class="left" href="#" phx-click="yellow_button_clicked"><span class="yellow_button_clicked"></span></a>
      <% else %>
        <a class="left" href="#" phx-click="yellow_button_clicked"><span></span></a>
      <% end %>
      <%= if @button_clicked == :blue do %>
        <a class="right" href="#" phx-click="blue_button_clicked"><span class="blue_button_clicked"></span></a>
      <% else %>
        <a class="right" href="#" phx-click="blue_button_clicked"><span></span></a>
      <% end %>
    </div>
    """
  end
end
