import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string

// Builds a set containing all numeric prefixes derived from right_numbers.
// Time: O(m * d), where m is count(right_numbers) and d is max digit length.
// Space: O(m * d) in the worst case for stored prefix values.
fn build_prefix_set(numbers: List(Int)) -> set.Set(Int) {
  numbers
  |> list.fold(from: set.new(), with: fn(prefix_set, number) {
    let #(_candidate_prefix_text, prefix_set) =
      number
      |> int.to_string
      |> string.to_graphemes
      |> list.fold(from: #("", prefix_set), with: fn(acc, digit_text) {
        let #(prefix_text, prefix_set) = acc
        let candidate_prefix_text = prefix_text |> string.append(digit_text)

        case int.parse(candidate_prefix_text) {
          Error(Nil) -> acc
          Ok(prefix_value) -> #(
            candidate_prefix_text,
            prefix_set |> set.insert(prefix_value),
          )
        }
      })

    prefix_set
  })
}

// Repeatedly trims the last digit until a matching prefix value is found.
// Time: O(d * log p), where d is digit length of number and p is prefix set size.
// Space: O(d) due to recursion depth.
fn find_matching_prefix_value(prefix_set: set.Set(Int), number: Int) -> Int {
  case prefix_set |> set.contains(number), number == 0 {
    True, _ | False, True -> number
    False, False -> find_matching_prefix_value(prefix_set, number / 10)
  }
}

// Returns the largest common numeric prefix value between two integer lists.
// Time: O(m * d + n * d * log p), where n is count(left_numbers),
// m is count(right_numbers), d is max digit length, and p is prefix set size.
// Space: O(m * d) for the prefix set.
fn max_common_prefix_value(
  left_numbers: List(Int),
  right_numbers: List(Int),
) -> Int {
  let prefix_set = build_prefix_set(right_numbers)
  left_numbers
  |> list.fold(from: 0, with: fn(max_prefix_value, number) {
    let matching_prefix_value = find_matching_prefix_value(prefix_set, number)

    case matching_prefix_value > max_prefix_value {
      True -> matching_prefix_value
      False -> max_prefix_value
    }
  })
}

// Manual smoke tests covering overlap, non-overlap, exact match, and zero cases.
pub fn run() {
  io.println("Case 1: basic overlap")
  let case1_left = [1, 10, 100]
  let case1_right = [1000]
  // Expected longest prefix value: 100
  echo max_common_prefix_value(case1_left, case1_right)

  io.println("Case 2: no overlap")
  let case2_left = [1, 2, 3]
  let case2_right = [4, 4, 4]
  // Expected longest prefix value: 0
  echo max_common_prefix_value(case2_left, case2_right)

  io.println("Case 3: multiple candidates")
  let case3_left = [567, 56, 890, 12]
  let case3_right = [56_111, 1299, 5]
  // Shared prefixes include 5, 56, and 12. Longest prefix value: 56
  echo max_common_prefix_value(case3_left, case3_right)

  io.println("Case 4: exact match and trimmed match")
  let case4_left = [54_321, 77, 9]
  let case4_right = [54_321, 543, 700]
  // Exact match 54321 should be returned as longest prefix value.
  echo max_common_prefix_value(case4_left, case4_right)

  io.println("Case 5: zero and single digit")
  let case5_left = [0, 10, 101]
  let case5_right = [0, 1, 999]
  // Prefix candidates include 0 and 1. Longest prefix value: 1
  echo max_common_prefix_value(case5_left, case5_right)
}
