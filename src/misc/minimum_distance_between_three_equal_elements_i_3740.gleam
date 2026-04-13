import gleam/int
import gleam/list

// Enumerate all ordered triplets of distinct indices (i, j, k).
// For each triplet where nums[i] == nums[j] == nums[k], compute the sum of
// absolute index differences. Track the minimum across all valid triplets.
//
// Distance formula: |i-j| + |j-k| + |i-k|
// Returns -1 if no valid triplet exists.
//
// Time:  O(n³) — three nested passes over the list
// Space: O(1)  — single accumulator, no auxiliary structures
fn minimum_distance(nums: List(Int)) {
  nums
  |> list.index_fold(from: -1, with: fn(result, outer_num, outer_index) {
    nums
    |> list.index_fold(from: result, with: fn(result, middle_num, middle_index) {
      nums
      |> list.index_fold(from: result, with: fn(result, inner_num, inner_index) {
        // Skip triplets that share any index — must be three distinct positions
        case
          outer_index == middle_index
          || middle_index == inner_index
          || outer_index == inner_index
        {
          True -> result

          False -> {
            // Only valid if all three elements are equal
            let is_good = outer_num == middle_num && middle_num == inner_num

            case is_good {
              True -> {
                // Sum of pairwise absolute index differences
                let distance =
                  int.absolute_value(outer_index - middle_index)
                  + int.absolute_value(middle_index - inner_index)
                  + int.absolute_value(inner_index - outer_index)
                distance
              }

              False -> result
            }
          }
        }
      })
    })
  })
}

pub fn run() {
  let n1 = [1, 2, 1, 1, 3]
  // Expected: 6
  echo minimum_distance(n1)

  let n2 = [1, 1, 2, 3, 2, 1, 2]
  // Expected: 8
  echo minimum_distance(n2)

  let n3 = [1]
  // Expected: -1 (fewer than three elements)
  echo minimum_distance(n3)
}
