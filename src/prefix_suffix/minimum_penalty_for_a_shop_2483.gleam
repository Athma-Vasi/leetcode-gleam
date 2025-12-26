import gleam/list
import gleam/result
import gleam/string

// Builds prefix array: count of 'N' (dissatisfied customers) before each hour
// Example: "YYNY" -> [0, 0, 0, 1, 1]
// Index i represents the penalty if shop opens after hour i
fn create_prefixes(visits: List(String)) -> List(Int) {
  let #(_prev, prefixes) =
    visits
    |> list.fold(from: #(0, [0]), with: fn(acc, visit) {
      let #(prev_penalty, prefixes) = acc
      case visit {
        "N" -> #(prev_penalty + 1, prefixes |> list.append([prev_penalty + 1]))
        // "Y" - no additional penalty
        _ -> #(prev_penalty, prefixes |> list.append([prev_penalty]))
      }
    })

  prefixes
}

// Builds suffix array: count of 'Y' (satisfied customers) from each hour onwards
// Example: "YYNY" -> [3, 2, 2, 1, 0]
// Index i represents missed customers if shop closes before hour i
fn create_suffixes(visits: List(String)) -> List(Int) {
  let #(_next, suffixes) =
    visits
    |> list.fold_right(from: #(0, [0]), with: fn(acc, visit) {
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
// Uses strict > comparison to track only hours with better penalties
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

    [prefix, ..rest_prefixes], [suffix, ..rest_suffixes] -> {
      // Total penalty at hour = N's before hour + Y's from hour onwards
      let penalty = prefix + suffix

      case penalty > minimum_penalty {
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
            [#(index, penalty), ..minimums],
            penalty,
            index + 1,
            rest_prefixes,
            rest_suffixes,
          )
      }
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
  let visits = string.to_graphemes(customer_visits)

  find_monotonically_decreasing_minimums(
    [],
    999_999_999,
    0,
    create_prefixes(visits),
    create_suffixes(visits),
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
