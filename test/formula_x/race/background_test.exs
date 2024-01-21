defmodule FormulaX.Race.BackgroundTest do
  use ExUnit.Case

  import Mock

  alias FormulaX.Fixtures
  alias FormulaX.Race.Background
  alias FormulaX.Utils

  test "initialize" do
    with_mock Utils, get_filenames_of_images!: fn _directory -> ["image1.jpg"] end do
      actual = Background.initialize(_race_distance = 25.0)

      expected = %Background{
        left_side_images: [
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg"
        ],
        right_side_images: [
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg",
          "image1.jpg"
        ],
        y_position: -60.0
      }

      assert actual === expected
    end
  end

  describe "move" do
    test "speed_boost_enabled?: true" do
      player_car = Fixtures.car(%{speed_boost_enabled?: true})

      actual =
        Fixtures.background()
        |> Background.move(player_car)

      expected = %Background{
        left_side_images: [
          "image1.png",
          "image2.png",
          "image3.png",
          "image4.png",
          "image5.png",
          "image6.png",
          "image7.png",
          "image8.png",
          "image9.png",
          "image10.png"
        ],
        right_side_images: [
          "image10.png",
          "image9.png",
          "image8.png",
          "image7.png",
          "image6.png",
          "image5.png",
          "image4.png",
          "image3.png",
          "image2.png",
          "image1.png"
        ],
        y_position: -1028.0
      }

      assert actual === expected
    end

    test "speed_boost_enabled?: false" do
      player_car = Fixtures.car()

      actual =
        Fixtures.background()
        |> Background.move(player_car)

      expected = %Background{
        left_side_images: [
          "image1.png",
          "image2.png",
          "image3.png",
          "image4.png",
          "image5.png",
          "image6.png",
          "image7.png",
          "image8.png",
          "image9.png",
          "image10.png"
        ],
        right_side_images: [
          "image10.png",
          "image9.png",
          "image8.png",
          "image7.png",
          "image6.png",
          "image5.png",
          "image4.png",
          "image3.png",
          "image2.png",
          "image1.png"
        ],
        y_position: -1031.0
      }

      assert actual === expected
    end
  end

  test "new" do
    actual =
      %{
        left_side_images: [
          "image1.png",
          "image2.png",
          "image3.png",
          "image4.png",
          "image5.png"
        ],
        right_side_images: [
          "image5.png",
          "image4.png",
          "image3.png",
          "image2.png",
          "image1.png"
        ],
        y_position: -500.0
      }
      |> Background.new()

    expected = %Background{
      left_side_images: [
        "image1.png",
        "image2.png",
        "image3.png",
        "image4.png",
        "image5.png"
      ],
      right_side_images: [
        "image5.png",
        "image4.png",
        "image3.png",
        "image2.png",
        "image1.png"
      ],
      y_position: -500.0
    }

    assert actual === expected
  end
end
