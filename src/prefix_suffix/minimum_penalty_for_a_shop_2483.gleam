import gleam/list
import gleam/result
import gleam/string

// Builds prefix array: count of 'N' (dissatisfied customers) before each hour
// Example: "YYNY" -> [0, 0, 0, 1, 1]
fn create_prefixes(visits: String) -> List(Int) {
  let initial = #(0, [0])
  let #(_prev, prefixes) =
    visits
    |> string.to_graphemes
    |> list.fold(from: initial, with: fn(acc, visit) {
      let #(prev_penalty, prefixes) = acc
      case visit {
        "N" -> #(prev_penalty + 1, [prev_penalty + 1, ..prefixes])
        // "Y" - no additional penalty
        _ -> #(prev_penalty, [prev_penalty, ..prefixes])
      }
    })

  list.reverse(prefixes)
}

// Builds suffix array: count of 'Y' (satisfied customers) from each hour onwards
// Example: "YYNY" -> [3, 2, 2, 1, 0]
fn create_suffixes(visits: String) -> List(Int) {
  let initial = #(0, [0])
  let #(_next, suffixes) =
    visits
    |> string.to_graphemes
    |> list.fold_right(from: initial, with: fn(acc, visit) {
      let #(next_penalty, suffixes) = acc
      case visit {
        "Y" -> #(next_penalty + 1, [next_penalty + 1, ..suffixes])
        // "N" - no additional penalty
        _ -> #(next_penalty, [next_penalty, ..suffixes])
      }
    })

  suffixes
}

// Iterates through all hours and collects (hour, penalty) pairs where penalty improves
// Maintains list of all improving penalties in descending hour order
fn find_monotonically_decreasing_minimums(
  minimums: List(#(Int, Int)),
  minimum_penalty: Int,
  index: Int,
  prefixes: List(Int),
  suffixes: List(Int),
) {
  case prefixes, suffixes {
    [], [] | [], _ | _, [] -> minimums

    [prefix, ..rest_prefixes], [suffix, ..rest_suffixes] ->
      // Total penalty at hour = N's before hour + Y's from hour onwards
      case prefix + suffix > minimum_penalty {
        True ->
          // Skip this hour, penalty is not better
          find_monotonically_decreasing_minimums(
            minimums,
            minimum_penalty,
            index + 1,
            rest_prefixes,
            rest_suffixes,
          )

        False ->
          // Found a better penalty, record this hour
          find_monotonically_decreasing_minimums(
            [#(index, prefix + suffix), ..minimums],
            prefix + suffix,
            index + 1,
            rest_prefixes,
            rest_suffixes,
          )
      }
  }
}

// Returns the earliest hour with minimum penalty from collected minimums
// List is in descending hour order, so first match with smallest penalty is earliest hour
fn pick_smallest(minimums: List(#(Int, Int))) -> Int {
  let first = minimums |> list.first |> result.unwrap(or: #(-1, -1))
  let #(smallest_index, _smallest_penalty) =
    minimums
    |> list.fold(from: first, with: fn(acc, tuple) {
      let #(_smallest_index, smallest_penalty) = acc
      let #(index, penalty) = tuple

      // When multiple hours have same minimum penalty, keep the earliest (largest index in desc list)
      case penalty == smallest_penalty {
        True -> #(index, penalty)
        False -> acc
      }
    })

  smallest_index
}

// Main solution: compute prefix and suffix arrays, then find best closing hour
// Time complexity: O(n) - three linear passes through input
// Space complexity: O(n) - storage for prefix and suffix arrays
fn find_minimum_penalty(customer_visits: String) -> Int {
  find_monotonically_decreasing_minimums(
    [],
    999_999_999,
    0,
    create_prefixes(customer_visits),
    create_suffixes(customer_visits),
  )
  |> pick_smallest
}

pub fn run() {
  let c1 = "YYNY"
  // 2
  echo find_minimum_penalty(c1)

  let c2 = "NNNNN"
  // 0
  echo find_minimum_penalty(c2)

  let c3 = "YYYY"
  // 4
  echo find_minimum_penalty(c3)
}
