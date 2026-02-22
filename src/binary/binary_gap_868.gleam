import gleam/int
import gleam/list
import gleam/string

// Converts any integer into its binary string representation.
//
// Examples:
// - 13 -> "1101"
// - 0 -> "0"
// - -5 -> "-101"
//
// Complexity:
// - Time: O(log |n|), dominated by repeated division by 2.
// - Space: O(log |n|), due to recursion depth and output size.
fn int_to_binary(value: Int) -> String {
  case value == 0 {
    True -> "0"
    False ->
      case value < 0 {
        True -> "-" <> int_to_binary_positive(0 - value)
        False -> int_to_binary_positive(value)
      }
  }
}

// Converts a positive integer to binary using recursive decomposition.
//
// This helper assumes n >= 0 and returns "" for n == 0 so that the caller can
// handle zero and sign formatting consistently.
//
// Complexity:
// - Time: O(log n)
// - Space: O(log n)
fn int_to_binary_positive(n: Int) -> String {
  case n == 0 {
    True -> ""
    False -> {
      let prefix = int_to_binary_positive(n / 2)
      let bit = case n % 2 == 0 {
        True -> "0"
        False -> "1"
      }
      prefix <> bit
    }
  }
}

// Computes the binary gap (LeetCode 868): the maximum distance between two
// consecutive '1' bits in the binary representation.
//
// Approach:
// - Iterate all bits with their indices.
// - Track the index of the most recent '1'.
// - When another '1' appears, update the best distance.
//
// Complexity:
// - Time: O(m), where m is the number of bits in the binary string.
// - Space: O(m) for grapheme conversion via string.to_graphemes.
fn longest_gap(binary: String) {
  let start_index = 0
  let initial_distance = 0

  let #(_start_index, distance) =
    binary
    |> string.to_graphemes
    |> list.index_fold(
      from: #(start_index, initial_distance),
      with: fn(acc, bit, curr_index) {
        let #(start_index, distance) = acc

        case bit {
          "1" -> #(curr_index, int.max(curr_index - start_index, distance))
          // "0"
          _ -> acc
        }
      },
    )

  distance
}

// Wrapper that converts to binary and then computes the longest binary gap.
//
// Complexity:
// - Time: O(log |n|)
// - Space: O(log |n|)
fn t(n: Int) {
  int_to_binary(n) |> longest_gap
}

pub fn run() {
  let n1 = 22
  // 2
  echo t(n1)

  let n2 = 8
  // 0
  echo t(n2)

  let n3 = 5
  // 2
  echo t(n3)
}
