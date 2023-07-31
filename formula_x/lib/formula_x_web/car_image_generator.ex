defmodule FormulaXWeb.CarImageGenerator do
  @moduledoc """
  This module should eventually receive x and y positions of cars from formula_x module and facilitate the display of cars.
  """
  def cars do
    [car1(), car2(), car3(), car4(), car5(), car6()]
  end

  defp car1 do
    %{
      image_source: "/images/cars/blue-red.png",
      position_class: "absolute top-[430px] right-[0px]"
    }
  end

  defp car2 do
    %{
      image_source: "/images/cars/blue.png",
      position_class: "absolute top-[290px] right-[0px]"
    }
  end

  defp car3 do
    %{
      image_source: "/images/cars/red.png",
      position_class: "absolute top-[430px] right-[-100px]"
    }
  end

  defp car4 do
    %{
      image_source: "/images/cars/white-with-spoiler.png",
      position_class: "absolute top-[290px] right-[-100px]"
    }
  end

  defp car5 do
    %{
      image_source: "/images/cars/white.png",
      position_class: "absolute top-[430px] right-[100px]"
    }
  end

  defp car6 do
    %{
      image_source: "/images/cars/yellow.png",
      position_class: "relative top-[290px] right-[100px]"
    }
  end
end
