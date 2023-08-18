defmodule FormulaX.Race.CarController do
  @moduledoc """
  Module which controls all cars except the player's car
  """
  alias FormulaX.Race

  use GenServer

  # -------------#
  # Client - API #
  # -------------#

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  ## ---------- ##
  # Server - API #
  ## -----------##

  def init(args) do
  end

  def handle_call() do
  end
end
