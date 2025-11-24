import gleam/dict
import gleam/list
import gleam/option
import gleam/order

type RemaindersThree {
  Zero
  One
  Two
}

fn group_remainders(nums: List(Int)) -> dict.Dict(RemaindersThree, List(Int)) {
  nums
  |> list.fold(from: dict.new(), with: fn(acc, num) {
    let remainder = num % 3
    let update = case remainder {
      0 -> Zero
      1 -> One
      _ -> Two
    }

    acc
    |> dict.upsert(update:, with: fn(remainder_nums_maybe) {
      case remainder_nums_maybe {
        option.None -> [num]
        option.Some(remainder_nums) -> [num, ..remainder_nums]
      }
    })
  })
}

fn int_compare(a: Int, b: Int) -> order.Order {
  case a < b {
    True -> order.Lt
    False ->
      case a == b {
        True -> order.Eq
        False -> order.Gt
      }
  }
}

fn process_remainders(
  grouped: dict.Dict(RemaindersThree, List(Int)),
  nums: List(Int),
) {
  let sum = nums |> list.fold(from: 0, with: fn(acc, num) { acc + num })
  let remainder = sum % 3

  case remainder {
    0 -> sum
    1 -> {
      // Need to remove numbers with total remainder 1
      // Option 1: remove one number with remainder 1
      // Option 2: remove two numbers with remainder 2
      let ones = case dict.get(grouped, One) {
        Ok(vals) -> vals |> list.sort(by: int_compare)
        Error(_) -> []
      }
      let twos = case dict.get(grouped, Two) {
        Ok(vals) -> vals |> list.sort(by: int_compare)
        Error(_) -> []
      }

      let option1 = case ones {
        [first, ..] -> sum - first
        [] -> -1
      }

      let option2 = case twos {
        [first, second, ..] -> sum - first - second
        _ -> -1
      }

      case option1 >= 0, option2 >= 0 {
        True, True ->
          case option1 > option2 {
            True -> option1
            False -> option2
          }
        True, False -> option1
        False, True -> option2
        False, False -> 0
      }
    }
    _ -> {
      // remainder is 2
      // Option 1: remove one number with remainder 2
      // Option 2: remove two numbers with remainder 1
      let ones = case dict.get(grouped, One) {
        Ok(vals) -> vals |> list.sort(by: int_compare)
        Error(_) -> []
      }
      let twos = case dict.get(grouped, Two) {
        Ok(vals) -> vals |> list.sort(by: int_compare)
        Error(_) -> []
      }

      let option1 = case twos {
        [first, ..] -> sum - first
        [] -> -1
      }

      let option2 = case ones {
        [first, second, ..] -> sum - first - second
        _ -> -1
      }

      case option1 >= 0, option2 >= 0 {
        True, True ->
          case option1 > option2 {
            True -> option1
            False -> option2
          }
        True, False -> option1
        False, True -> option2
        False, False -> 0
      }
    }
  }
}

fn t(nums: List(Int)) {
  group_remainders(nums) |> process_remainders(nums)
}

pub fn run() {
  let n1 = [3, 6, 5, 1, 8]
  // 18
  echo t(n1)

  let n2 = [4]
  // 0
  echo t(n2)

  let n3 = [1, 2, 3, 4, 4]
  // 12
  echo t(n3)
}
