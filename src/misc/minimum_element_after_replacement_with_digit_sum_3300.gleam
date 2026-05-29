import gleam/int
import gleam/list
import gleam/string

// Replaces each number by its digit sum and returns the minimum resulting value.
// Time: O(n * d), where n is the number of elements and d is the average digit count.
// Space: O(d) per element due to string/grapheme conversion.
fn find_minimum_element(nums: List(Int)) {
  let max_signed_32_bit_integer = 2_147_483_647

  nums
  |> list.fold(from: max_signed_32_bit_integer, with: fn(minimum, num) {
    // Compute the digit sum of the current number.
    let digit_sum =
      num
      |> int.to_string
      |> string.to_graphemes
      |> list.fold(from: 0, with: fn(sum, grapheme) {
        case int.parse(grapheme) {
          Error(Nil) -> sum
          Ok(digit) -> sum + digit
        }
      })

    case digit_sum < minimum {
      True -> digit_sum
      False -> minimum
    }
  })
}

pub fn run() {
  let n1 = [10, 12, 13, 14]
  // 1
  echo find_minimum_element(n1)

  let n2 = [1, 2, 3, 4]
  // 1
  echo find_minimum_element(n2)

  let n3 = [999, 19, 199]
  // 10
  echo find_minimum_element(n3)
}
