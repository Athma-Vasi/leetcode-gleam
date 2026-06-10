// LeetCode 1752 – Check if Array Is Sorted and Rotated
//
// A non-decreasing array that has been rotated (possibly zero times) has at
// most one "descent" — a position where nums[i] > nums[i+1], wrapping around
// so the last element is compared against the first.
// Count descents; the array is valid iff the total is ≤ 1.
//
// Time : O(n)
// Space: O(1)

import gleam/list
import gleam/result

/// Returns true if `nums` could be a non-decreasing array rotated 0–n times.
/// Counts the number of descending adjacent pairs (including the wrap-around
/// pair last→first); a valid rotated-sorted array has at most one such descent.
///
/// Time : O(n)
/// Space: O(1)
fn check(nums: List(Int)) {
  let initial_count = 0
  let initial_prev = 0
  let initial_acc = #(initial_count, initial_prev)

  // Count adjacent descents in left-to-right order.
  let #(count, _prev) =
    nums
    |> list.fold(from: initial_acc, with: fn(acc, num) {
      let #(count, prev) = acc
      case prev > num {
        True -> #(count + 1, num)
        False -> #(count, num)
      }
    })

  let first = list.first(nums) |> result.unwrap(or: -1)
  let last = list.last(nums) |> result.unwrap(or: -1)

  // Account for the wrap-around descent (last element > first element),
  // which occurs at the rotation boundary.
  let count = case last > first {
    True -> count + 1
    False -> count
  }

  count <= 1
}

pub fn run() {
  let n1 = [3, 4, 5, 1, 2]
  // true
  echo check(n1)

  let n2 = [2, 1, 3, 4]
  // false
  echo check(n2)

  let n3 = [1, 2, 3]
  // true
  echo check(n3)
}
