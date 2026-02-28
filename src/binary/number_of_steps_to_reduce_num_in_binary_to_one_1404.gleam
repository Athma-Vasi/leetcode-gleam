import gleam/int
import gleam/list
import gleam/result
import gleam/string

/// Converts a binary string into a list of integer bits.
/// Splits the string into individual characters, parses each to an integer, and returns a list.
/// Time Complexity: O(n) where n is the length of the input string
/// Space Complexity: O(n) for storing the resulting list of bits
fn binary_string_to_bits(str: String) {
  str
  |> string.to_graphemes
  |> list.fold(from: [], with: fn(acc, bit_string) {
    acc |> list.append([bit_string |> int.parse |> result.unwrap(or: 0)])
  })
}

/// Converts a list of binary digits into an integer using binary-to-decimal conversion.
/// Uses left-to-right fold, doubling the accumulated value and adding each bit.
/// Time Complexity: O(n) where n is the number of bits
/// Space Complexity: O(1) - only maintains a single accumulator
fn bits_to_int(bits: List(Int)) -> Int {
  bits
  |> list.fold(from: 0, with: fn(value, bit) { value * 2 + bit })
}

/// Recursively reduces a number to 1 and counts the steps taken.
/// Even numbers: divide by 2. Odd numbers: add 1. Continues until reaching 1.
/// Time Complexity: O(log n) where n is the input number
/// Space Complexity: O(log n) for recursion stack depth
fn reduce_num(reduced: Int, step_count: Int) {
  case reduced == 1 {
    True -> step_count

    False ->
      case int.is_even(reduced) {
        True -> reduce_num(reduced / 2, step_count + 1)
        False -> reduce_num(reduced + 1, step_count + 1)
      }
  }
}

fn calculate_reduction_steps(str: String) {
  str |> binary_string_to_bits |> bits_to_int |> reduce_num(0)
}

pub fn run() {
  let s1 = "1101"
  // 6
  echo calculate_reduction_steps(s1)

  let s2 = "10"
  // 1
  echo calculate_reduction_steps(s2)

  let s3 = "1"
  // 0
  echo calculate_reduction_steps(s3)
}
