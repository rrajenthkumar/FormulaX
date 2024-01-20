defmodule FormulaX.ResultTest do
  use ExUnit.Case

  alias FormulaX.Fixtures
  alias FormulaX.Result

  describe "get_player_car_result" do
    test "crashed" do
      actual =
        Fixtures.race(%{status: :crash})
        |> Result.get_player_car_result()

      expected = %Result{car: "car.png", status: :crashed}

      assert actual === expected
    end

    test "completed" do
      race =
        Fixtures.race(%{
          player_car: Fixtures.car(%{completion_time: ~T[19:16:19.178386]}),
          autonomous_cars: [
            Fixtures.car(%{
              id: 2,
              controller: :autonomous,
              completion_time: ~T[19:15:19.178386]
            }),
            Fixtures.car(%{
              id: 3,
              controller: :autonomous,
              completion_time: ~T[19:17:19.178386]
            }),
            Fixtures.car(%{
              id: 4,
              controller: :autonomous,
              completion_time: ~T[19:18:19.178386]
            }),
            Fixtures.car(%{id: 5, controller: :autonomous}),
            Fixtures.car(%{id: 6, controller: :autonomous})
          ],
          start_time: ~T[19:12:19.178386],
          status: :ended
        })

      actual = Result.get_player_car_result(race)

      expected = %Result{
        car: "car.png",
        status: :completed,
        time: 240,
        position: 2
      }

      assert actual === expected
    end
  end

  test "update_last_5_results" do
    new_result =
      Fixtures.result(%{
        car: "car1.png",
        status: :completed,
        position: 2
      })

    last_5_results = [
      Fixtures.result(%{
        car: "car2.png",
        time: 230,
        position: 5,
        symbol: "&#8681"
      }),
      Fixtures.result(%{
        car: "car3.png",
        time: 150,
        position: 1,
        symbol: "&#127942"
      }),
      Fixtures.result(%{
        car: "car4.png",
        status: :crashed,
        symbol: "&#128555"
      }),
      Fixtures.result(%{
        car: "car5.png",
        status: :completed,
        time: 230,
        position: 3,
        symbol: "&#8679"
      }),
      Fixtures.result(%{
        car: "car6.png",
        status: :crashed,
        symbol: "&#128555"
      })
    ]

    actual = Result.update_last_5_results(new_result, last_5_results)

    expected = [
      Fixtures.result(%{
        car: "car1.png",
        status: :completed,
        position: 2,
        symbol: "&#8679"
      }),
      Fixtures.result(%{
        car: "car2.png",
        time: 230,
        position: 5,
        symbol: "&#8681"
      }),
      Fixtures.result(%{
        car: "car3.png",
        time: 150,
        position: 1,
        symbol: "&#127942"
      }),
      Fixtures.result(%{
        car: "car4.png",
        status: :crashed,
        symbol: "&#128555"
      }),
      Fixtures.result(%{
        car: "car5.png",
        status: :completed,
        time: 230,
        position: 3,
        symbol: "&#8679"
      })
    ]

    assert actual === expected
  end

  test "new" do
    actual =
      %{
        car: "car.png",
        status: :completed,
        time: 180,
        position: 6
      }
      |> Result.new()

    expected = %Result{
      car: "car.png",
      status: :completed,
      time: 180,
      position: 6
    }

    assert actual === expected
  end
end
