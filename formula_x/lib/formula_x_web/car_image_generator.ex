defmodule FormulaXWeb.CarImageGenerator do
  @moduledoc """
  This module should eventially receive x and y positions of cars from formula_x module and facilitate the display of cars.
  """
  def cars do
    [car1(), car2(), car3(), car4(), car5(), car6()]
  end

  defp car1 do
    %{
      image_source: "/images/cars/blue-red.png",
      class: "w-14 inline-block relative top-[430px] right-[-50px]"
    }
  end

  defp car2 do
    %{
      image_source: "/images/cars/blue.png",
      class: "w-14 inline-block relative top-[300px] right-[10px]"
    }
  end

  defp car3 do
    %{
      image_source: "/images/cars/red.png",
      class: "w-14 inline-block relative top-[430px] right-[-30px]"
    }
  end

  defp car4 do
    %{
      image_source: "/images/cars/white-with-spoiler.png",
      class: "w-14 inline-block relative top-[300px] right-[30px]"
    }
  end

  defp car5 do
    %{
      image_source: "/images/cars/white.png",
      class: "w-14 inline-block relative top-[430px] right-[-10px]"
    }
  end

  defp car6 do
    %{
      image_source: "/images/cars/yellow.png",
      class: "w-14 inline-block relative top-[300px] right-[50px]"
    }
  end
end
