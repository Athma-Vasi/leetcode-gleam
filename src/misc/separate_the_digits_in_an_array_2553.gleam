// LeetCode 2553 – Separate the Digits in an Array
//
// Replace each integer in the array with its individual digits, preserving
// the original order of both numbers and digits within each number.
//
// Time : O(n * d)  – n = length of nums, d = max digit count per number
// Space: O(n * d)  – the expanded output list

import gleam/int
import gleam/list
import gleam/string

/// Converts a non-negative integer into its ordered list of decimal digits.
///
/// Time : O(d)  – d = number of digits
/// Space: O(d)
fn convert_to_digits(num: Int) {
  num
  |> int.to_string
  |> string.to_graphemes
  |> list.fold(from: [], with: fn(digits, grapheme) {
    case int.parse(grapheme) {
      Error(Nil) -> digits
      Ok(digit) -> [digit, ..digits]
    }
  })
  |> list.reverse
}

/// Expands every number in `nums` into its constituent digits in order.
/// Uses head-cons accumulation (reversing the input first, then each digit
/// list) to achieve O(n * d) without quadratic list appends.
///
/// Time : O(n * d)
/// Space: O(n * d)
fn separate(nums: List(Int)) {
  nums
  |> list.reverse
  |> list.fold(from: [], with: fn(acc, num) {
    num
    |> convert_to_digits
    |> list.reverse
    |> list.fold(from: acc, with: fn(acc, digit) { [digit, ..acc] })
  })
}

pub fn run() {
  let n1 = [13, 25, 83, 77]
  // [1,3,2,5,8,3,7,7]
  echo separate(n1)

  let n2 = [7, 1, 3, 9]
  // [7, 1, 3, 9]
  echo separate(n2)
}
