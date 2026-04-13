import gleam/dict
import gleam/int
import gleam/list
import gleam/option

// Optimised approach: group indices by value, then for each value that appears
// at least three times, the minimum-cost triplet is always the outermost pair
// (first and last occurrence). The distance formula simplifies to:
//   |i-j| + |j-k| + |i-k| = 2 * (last - first)  for any i ≤ j ≤ k
//
// Returns the global minimum across all qualifying values, or -1 if none exist.
//
// Time:  O(n) — one pass to build the table, one pass over distinct values
// Space: O(n) — dict storing all indices per value

// Build a dict mapping each value to the ordered list of its indices.
fn create_table(nums: List(Int)) -> dict.Dict(Int, List(Int)) {
  nums
  |> list.index_fold(from: dict.new(), with: fn(table, num, index) {
    table
    |> dict.upsert(update: num, with: fn(indices_maybe) {
      case indices_maybe {
        option.None -> [index]
        // Append to preserve insertion order (indices are visited in order)
        option.Some(indices) -> indices |> list.append([index])
      }
    })
  })
}

// For each value with >= 3 occurrences, compute the minimum triplet distance
// using only its first and last index. Track the global minimum.
fn minimum_distance(table: dict.Dict(Int, List(Int))) -> Int {
  table
  |> dict.fold(from: -1, with: fn(result, _num, indices) {
    // Skip values that appear fewer than three times — no valid triplet
    case list.length(indices) < 3 {
      True -> result

      False -> {
        case list.first(indices), list.last(indices) {
          // Unreachable for a non-empty list, but handled exhaustively
          Ok(_), Error(Nil) | Error(Nil), Ok(_) | Error(Nil), Error(Nil) ->
            result

          Ok(first_index), Ok(last_index) -> {
            // |i-j| + |j-k| + |i-k| = 2*(last-first) for any middle index j
            let distance = { last_index - first_index } * 2
            // Use -1 as "no result yet" sentinel; avoid int.min(-1, distance)
            // which would incorrectly keep -1 as the minimum
            case result {
              -1 -> distance
              _ -> int.min(result, distance)
            }
          }
        }
      }
    }
  })
}

fn t(nums: List(Int)) -> Int {
  create_table(nums) |> minimum_distance
}

pub fn run() {
  let n1 = [1, 2, 1, 1, 3]
  // Expected: 6
  echo t(n1)

  let n2 = [1, 1, 2, 3, 2, 1, 2]
  // Expected: 8
  echo t(n2)

  let n3 = [1]
  // Expected: -1 (fewer than three elements)
  echo t(n3)
}
