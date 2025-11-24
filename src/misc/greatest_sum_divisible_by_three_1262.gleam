import gleam/dict
import gleam/list
import gleam/option
import gleam/order

pub type RemaindersThree {
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

fn remainders_compare(
  a: #(RemaindersThree, List(Int)),
  with b: #(RemaindersThree, List(Int)),
) {
  let #(a_remainder, _) = a
  let #(b_remainder, _) = b

  case a_remainder, b_remainder {
    Zero, Zero -> order.Eq
    Zero, One -> order.Lt
    Zero, Two -> order.Lt
    One, Zero -> order.Gt
    One, One -> order.Eq
    One, Two -> order.Lt
    Two, Zero -> order.Lt
    Two, One -> order.Lt
    Two, Two -> order.Eq
  }
}

fn process(greatest: Int, found: Bool, sorted_nums: List(List(Int))) {
  case found, sorted_nums {
    True, [] | True, _ | False, [] -> greatest

    False, [nums, ..rest] -> {
      let #(exists, found_num) =
        nums
        |> list.fold(from: #(False, -1), with: fn(acc, num) {
          let #(exists, _found_num) = acc
          case exists, { greatest - num } % 3 == 0 {
            True, True -> #(True, num)
            True, False | False, True | False, False -> acc
          }
        })

      process(greatest - found_num, exists, rest)
    }
  }
}

fn process_remainders(
  grouped: dict.Dict(RemaindersThree, List(Int)),
  nums: List(Int),
) {
  let sum = nums |> list.fold(from: 0, with: fn(acc, num) { acc + num })
  let sorted_nums =
    grouped
    |> dict.to_list
    |> list.sort(by: remainders_compare)
    |> list.fold(from: [], with: fn(acc, tuple) {
      let #(_remainder, nums) = tuple
      acc |> list.append([nums])
    })
  process(sum, False, sorted_nums)
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
