defmodule FormulaX.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FormulaXWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: FormulaX.PubSub},
      # Start Finch
      {Finch, name: FormulaX.Finch},
      # Start the Endpoint (http/https)
      FormulaXWeb.Endpoint
      # Start a worker by calling: FormulaX.Worker.start_link(arg)
      # {FormulaX.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FormulaX.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FormulaXWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
