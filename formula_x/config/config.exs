# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# All the parameters used in calculations done for Race visualisation
config :formula_x,
  parameters: %{
    # Total race distance
    race_distance: 650.0,
    # Based on CSS styling of 'screen' class
    console_screen_height: 35.0,
    # List of lane info maps
    # x_start and x_end are the limits of a lane along the X axis
    # Based on CSS styling of 'race_screen' class
    lanes: [
      %{lane_number: 1, x_start: 0.0, x_end: 6.0},
      %{lane_number: 2, x_start: 6.0, x_end: 12.0},
      %{lane_number: 3, x_start: 12.0, x_end: 18.0}
    ],
    # Based on CSS styling of 'car' class
    # Please note that the car length should be <= the highest drive step value for crash detection to work.
    # Lengths of race elements like speed boosts, obstacles are also set to the same value for ease of calculations
    car_length: 7.0,
    # Initial positions of cars during the start of a race
    car_initial_positions: [
      {1.25, 1.0},
      {7.25, 1.0},
      {13.25, 1.0},
      {1.25, 9.0},
      {7.25, 9.0},
      {13.25, 9.0}
    ],
    # Car drive steps map with Y direction step values for different speeds
    # Don't enter a car drive step value that is > car length (7rem). Crash detection will fail.
    car_drive_steps: %{rest: 0.0, low: 4.0, moderate: 5.0, high: 6.0, speed_boost: 7.0},
    # Car steering X direction step value
    car_steering_step: 6.0,
    # Obstacles and Speed boosts are not placed until this distance after the start of race
    obstacles_and_speed_boosts_free_distance: 60.0,
    # Y direction step values used to position Obstacles
    obstacle_y_position_steps: [30.0, 60.0, 90.0],
    # Y direction step value used to position Speed boosts
    # These are rare elements and so the step value is set high
    speed_boost_y_position_step: 300.0
  }

# Configures the endpoint
config :formula_x, FormulaXWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: FormulaXWeb.ErrorHTML, json: FormulaXWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: FormulaX.PubSub,
  live_view: [signing_salt: "064G0l++"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :formula_x, FormulaX.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
