import gleam/int
import gleam/list
import gleam/result
import gleam/string

/// Converts a positive integer to its binary string representation.
/// Uses recursive division by 2, building the binary string from right to left.
/// Time Complexity: O(log n) where n is the input number
/// Space Complexity: O(log n) for recursion stack and resulting string
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

/// Converts any integer (including 0 and negatives) to binary string.
/// Handles edge cases: 0 returns "0", negatives are prefixed with "-".
/// Time Complexity: O(log |value|)
/// Space Complexity: O(log |value|)
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

/// Recursively builds a string by concatenating binary representations from 1 to n.
/// Counts down from n to 1, prepending each binary string to the accumulator.
/// Time Complexity: O(n * log n) - n iterations, each converting O(log n) sized number
/// Space Complexity: O(n * log n) - total length of concatenated binary string
fn concatenate_to_binary_string(subtracted: Int, concatenated: String) {
  case subtracted == 0 {
    True -> concatenated

    False -> {
      concatenate_to_binary_string(
        subtracted - 1,
        int_to_binary(subtracted) <> concatenated,
      )
    }
  }
}

/// Converts a binary string into a list of integer bits (0s and 1s).
/// Splits string into characters and parses each to an integer.
/// Time Complexity: O(m) where m is the length of the string
/// Space Complexity: O(m) for the resulting list of bits
fn binary_string_to_bits(str: String) {
  str
  |> string.to_graphemes
  |> list.fold(from: [], with: fn(acc, bit_string) {
    acc |> list.append([bit_string |> int.parse |> result.unwrap(or: 0)])
  })
}

/// Converts a list of binary digits to an integer with modulo 10^9 + 7.
/// Applies modulo at each step to prevent overflow for large binary numbers.
/// Time Complexity: O(m) where m is the number of bits
/// Space Complexity: O(1) - only maintains a single accumulator
fn bits_to_int(bits: List(Int)) -> Int {
  let modulo = 1_000_000_007
  bits
  |> list.fold(from: 0, with: fn(value, bit) { { value * 2 + bit } % modulo })
}

/// Main function: concatenates binary representations from 1 to n and returns decimal value mod 10^9+7.
/// Pipeline: n -> concatenated binary string -> list of bits -> integer with modulo.
/// Time Complexity: O(n * log n) - dominated by string concatenation and conversion
/// Space Complexity: O(n * log n) - for storing the concatenated binary string
fn calculate_decimal_value(num: Int) {
  num
  |> concatenate_to_binary_string("")
  |> binary_string_to_bits
  |> bits_to_int
}

pub fn run() {
  let n1 = 1
  // 1
  echo calculate_decimal_value(n1)

  let n2 = 3
  // 27
  echo calculate_decimal_value(n2)

  let n3 = 12
  // 505379714
  echo calculate_decimal_value(n3)
}
