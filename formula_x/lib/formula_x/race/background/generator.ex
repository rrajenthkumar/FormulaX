defmodule FormulaX.Race.Background.Generator do
  def generate_background(list_of_background_items) do
    case(File.read("/images/background"))
    {:ok, list_of_background_items} -> Enum.map(1..100, fn x -> Enum.random(list_of_background_items) end)
      error -> error
  end
end
