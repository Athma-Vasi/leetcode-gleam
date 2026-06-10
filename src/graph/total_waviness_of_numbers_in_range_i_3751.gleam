// LeetCode 3751 – Total Waviness of Numbers in Range I
//
// A digit at position i (0-indexed) is "wavy" if it is a strict local extremum:
//   strictly greater than both neighbours  (local maximum), or
//   strictly less than both neighbours     (local minimum).
// The waviness of a number is the count of its wavy digits.
// Return the sum of waviness for every integer in [num1, num2].
//
// Approach: for each number, build an adjacency map keyed by (digit, index)
// that records the left and right neighbours of every digit position, then
// count local extrema across all numbers.
//
// Overall Time  : O(n * d)  – n = range size, d = max digit count
// Overall Space : O(n * d)

import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/string

// Left-neighbour of a digit: None when the digit is the first in the number.
type LeftDigitResult =
  Result(Int, Nil)

// Right-neighbour of a digit: None when the digit is the last in the number.
type RightDigitResult =
  Result(Int, Nil)

// Maps (digit_value, position_index) → (left_neighbour, right_neighbour).
type AdjacencyMap =
  dict.Dict(#(Int, Int), #(LeftDigitResult, RightDigitResult))

/// Converts an integer into its ordered list of decimal digits.
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

/// Builds the inclusive integer range [num1, num2] as a list.
/// Uses tail-recursive accumulation to avoid stack overflow.
///
/// Time : O(n)  – n = num2 - num1 + 1
/// Space: O(n)
fn build_range(num1: Int, num2: Int, result: List(Int)) {
  case num1 == num2 {
    True -> [num1, ..result] |> list.reverse
    False -> build_range(num1 + 1, num2, [num1, ..result])
  }
}

/// Records the left-neighbour edge for the current digit at `index`
/// in the adjacency map. Preserves any existing right-neighbour entry.
///
/// Time : O(1) amortised (dict upsert)
fn update_left_edge(
  graph: AdjacencyMap,
  left_digit_result: Result(Int, Nil),
  current_digit: Int,
  index: Int,
) {
  graph
  |> dict.upsert(update: #(current_digit, index), with: fn(edges_maybe) {
    case left_digit_result, edges_maybe {
      // First digit in the number: no left neighbour, no entry yet.
      Error(Nil), option.None -> #(Error(Nil), Error(Nil))

      // First digit, but a right-neighbour entry already exists.
      Error(Nil), option.Some(edges) -> {
        let #(_left_digit_result, right_digit_result) = edges
        #(Error(Nil), right_digit_result)
      }

      // Has a left neighbour, no existing entry.
      Ok(left_digit), option.None -> #(Ok(left_digit), Error(Nil))

      // Has a left neighbour; preserve the existing right-neighbour entry.
      Ok(left_digit), option.Some(edges) -> {
        let #(_left_digit_result, right_digit_result) = edges
        #(Ok(left_digit), right_digit_result)
      }
    }
  })
}

/// Records the right-neighbour edge for the *previous* digit (at index - 1)
/// in the adjacency map. No-op when there is no previous digit.
///
/// Time : O(1) amortised (dict upsert)
fn update_right_edge(
  graph: AdjacencyMap,
  left_digit_result: Result(Int, Nil),
  current_digit: Int,
  index: Int,
) {
  case left_digit_result {
    // No previous digit – nothing to update.
    Error(Nil) -> graph

    Ok(left_digit) ->
      graph
      |> dict.upsert(update: #(left_digit, index - 1), with: fn(edges_maybe) {
        case edges_maybe {
          // No existing entry for the previous digit.
          option.None -> #(Error(Nil), Ok(current_digit))

          // Preserve the existing left-neighbour; set the right-neighbour.
          option.Some(edges) -> {
            let #(left_digit_result, _right_digit_result) = edges
            #(left_digit_result, Ok(current_digit))
          }
        }
      })
  }
}

/// Builds an adjacency map for a single number represented as a digit list.
/// Each entry records the left and right neighbours of every digit position,
/// enabling O(d) local-extremum detection in `determine_total_waviness`.
///
/// Time : O(d)  – one dict upsert per digit
/// Space: O(d)
fn build_graph(digits: List(Int)) {
  let initial_left_digit_result = Error(Nil)
  let initial_graph: AdjacencyMap = dict.new()
  let initial_acc = #(initial_left_digit_result, initial_graph)

  let #(_left_digit_result, graph) =
    digits
    |> list.index_fold(from: initial_acc, with: fn(acc, current_digit, index) {
      let #(left_digit_result, graph) = acc

      let updated_graph =
        graph
        |> update_left_edge(left_digit_result, current_digit, index)
        |> update_right_edge(left_digit_result, current_digit, index)

      #(Ok(current_digit), updated_graph)
    })

  graph
}

/// Converts every integer in `range` into an adjacency map via `build_graph`.
/// Results are collected in order (head-consed then reversed for O(n) builds).
///
/// Time : O(n * d)  – n numbers, each requiring O(d) graph construction
/// Space: O(n * d)
fn build_graphs(range: List(Int)) {
  let initial_graphs: List(AdjacencyMap) = []

  range
  |> list.fold(from: initial_graphs, with: fn(graphs, num) {
    let graph = num |> convert_to_digits |> build_graph
    [graph, ..graphs]
  })
  |> list.reverse
}

/// Sums the waviness across all adjacency maps.
/// A digit at position i contributes 1 to the waviness if and only if it has
/// both a left and a right neighbour AND is a strict local extremum.
///
/// Time : O(n * d)  – iterates every entry of every adjacency map
/// Space: O(1)      – only accumulates an integer counter
fn determine_total_waviness(graphs: List(AdjacencyMap)) {
  graphs
  |> list.fold(from: 0, with: fn(total, graph) {
    graph
    |> dict.fold(from: total, with: fn(total, key, value) {
      let #(left_edge_result, right_edge_result) = value
      let #(digit, _index) = key

      case left_edge_result, right_edge_result {
        // A digit cannot appear without both neighbours being absent simultaneously
        // (single-digit numbers have no interior digits); skip.
        Error(Nil), Error(Nil) -> total

        // First digit (no left neighbour): cannot be a local extremum.
        Error(Nil), Ok(_right_edge) -> total

        // Last digit (no right neighbour): cannot be a local extremum.
        Ok(_left_edge), Error(Nil) -> total

        // Interior digit: wavy if strictly greater OR strictly less than both neighbours.
        Ok(left_edge), Ok(right_edge) ->
          case
            { digit > left_edge && digit > right_edge }
            || { digit < left_edge && digit < right_edge }
          {
            True -> total + 1
            False -> total
          }
      }
    })
  })
}

/// Entry point: computes the total waviness of all integers in [num1, num2].
///
/// Time : O(n * d)  – n = num2 - num1 + 1, d = max digits
/// Space: O(n * d)
fn t(num1: Int, num2: Int) {
  build_range(num1, num2, [])
  |> build_graphs
  |> determine_total_waviness
}

pub fn run() {
  // --- original examples ---

  let n1 = 120
  let n11 = 130
  // expected: 3
  // 120→[1,2,0] 2 is peak; 121→[1,2,1] 2 is peak; 130→[1,3,0] 3 is peak
  echo t(n1, n11)

  let n2 = 198
  let n22 = 202
  // expected: 3
  // 198→[1,9,8] peak; 201→[2,0,1] valley; 202→[2,0,2] valley
  echo t(n2, n22)

  let n3 = 4848
  let n33 = 4848
  // expected: 2
  // [4,8,4,8]: 8 at idx1 is peak; 4 at idx2 is valley
  echo t(n3, n33)

  // --- additional test cases ---

  // single-digit numbers have no interior positions → waviness always 0
  let n4 = 1
  let n44 = 9
  // expected: 0
  echo t(n4, n44)

  // two-digit numbers have no interior positions → waviness always 0
  let n5 = 10
  let n55 = 99
  // expected: 0
  echo t(n5, n55)

  // single valley: [1,0,1] → 0 at idx1 is a strict local minimum
  let n6 = 101
  let n66 = 101
  // expected: 1
  echo t(n6, n66)

  // range 100–110:
  //   100 [1,0,0]: 0 at idx1 left=1,right=0 → 0<1 but not 0<0 → not wavy
  //   101–109 each have a valley at idx1 (0 < both neighbours)
  //   110 [1,1,0]: 1 at idx1 not strictly less/greater than both → not wavy
  // expected: 9
  let n7 = 100
  let n77 = 110
  // expected: 9
  echo t(n7, n77)

  // single peak at centre: [1,2,3,2,1] → 3 at idx2 is the only local max
  let n8 = 12_321
  let n88 = 12_321
  // expected: 1
  echo t(n8, n88)

  // maximum interior extrema for a 5-digit number:
  // [1,0,1,0,1] → idx1(0) valley, idx2(1) peak, idx3(0) valley → 3 wavy digits
  let n9 = 10_101
  let n99 = 10_101
  // expected: 3
  echo t(n9, n99)

  // same structure with large digits:
  // [9,8,9,8,9] → idx1(8) valley, idx2(9) peak, idx3(8) valley → 3 wavy digits
  let n10 = 98_989
  let n1010 = 98_989
  // expected: 3
  echo t(n10, n1010)

  // [1,9,1,9,1] → idx1(9) peak, idx2(1) valley, idx3(9) peak → 3 wavy digits
  let n11 = 19_191
  let n1111 = 19_191
  // expected: 3
  echo t(n11, n1111)

  // strictly increasing digits → no local extrema anywhere
  let n12 = 12_345
  let n1212 = 12_345
  // expected: 0
  echo t(n12, n1212)

  // strictly decreasing digits → no local extrema anywhere
  let n13 = 54_321
  let n1313 = 54_321
  // expected: 0
  echo t(n13, n1313)

  // upper boundary: [1,0,0,0,0,0] → no strict local extrema (all interior 0s tie)
  let n14 = 100_000
  let n1414 = 100_000
  // expected: 0
  echo t(n14, n1414)
}
