defmodule FormulaX.UtilsTest do
  use ExUnit.Case

  alias FormulaX.Utils

  test "get_filenames_of_images!" do
    returned_images = Utils.get_filenames_of_images!("cars")

    all_images_in_folder = [
      "blue-red.png",
      "blue-with-spoiler.png",
      "blue.png",
      "red.png",
      "white-cabriolet.png",
      "white-with-spoiler.png",
      "white.png",
      "yellow-red.png",
      "yellow.png"
    ]

    assert returned_images -- all_images_in_folder === []
  end
end
