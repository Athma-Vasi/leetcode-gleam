import gleam/int
import gleam/list
import gleam/result

// LeetCode 2078 - Two Furthest Houses With Different Colors
// https://leetcode.com/problems/two-furthest-houses-with-different-colors/
//
// Key insight: the optimal pair always involves either the first or the last house.
// Proof: if neither endpoint is in the optimal pair (i, j), we can extend it
// outward to the endpoint that differs in color — only improving the distance.
//
// Strategy: single pass over every house h at index i.
//   - Candidate 1: distance from house[0] (first) to h, valid when colors differ.
//   - Candidate 2: distance from h to house[n-1] (last), valid when colors differ.
//   Track the running maximum across both candidates.
//
// Time  : O(n) — one index_fold over the list
// Space : O(1) — only scalar accumulators
fn furthest_houses(houses: List(Int)) {
  let first_color = houses |> list.first |> result.unwrap(or: -1)
  let last_color = houses |> list.last |> result.unwrap(or: -1)
  let length = list.length(houses)

  houses
  |> list.index_fold(from: 0, with: fn(max_dist, color, index) {
    // Distance from the first house to this house (0 if same color)
    let from_start = case color != first_color {
      True -> index
      False -> 0
    }
    // Distance from this house to the last house (0 if same color)
    let from_end = case color != last_color {
      True -> length - 1 - index
      False -> 0
    }
    int.max(max_dist, int.max(from_start, from_end))
  })
}

pub fn run() {
  let c1 = [1, 1, 1, 6, 1, 1, 1]
  // 3
  echo furthest_houses(c1)

  let c2 = [1, 8, 3, 8, 3]
  // 4
  echo furthest_houses(c2)

  let c3 = [0, 1]
  // 1
  echo furthest_houses(c3)
}
