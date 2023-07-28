defmodule FormulaXWeb.RaceLive do
  use FormulaXWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="race_live">
      <div class="console">
        <div class="screen"></div>
      </div>
    </div>
    """
  end

  def mount(_params, %{}, socket) do
    {:ok, socket}
  end
end
