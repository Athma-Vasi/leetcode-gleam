// LeetCode 2144 – Minimum Cost of Buying Candies With Discount
//
// Every 3rd candy (in order of descending price) is free.
// Greedy: sort descending so the most expensive candy in each free slot
// is maximised, minimising total paid.
//
// Time : O(n log n)  – dominated by the sort
// Space: O(n)        – sorted list + accumulated bought list

import gleam/int
import gleam/list

/// Computes the minimum total cost after applying the buy-2-get-1-free discount.
/// Sorts prices descending, then skips every 3rd item (the free one).
///
/// Time : O(n log n)  – sort + single O(n) fold
/// Space: O(n)
fn minimum_cost(costs: List(Int)) {
  let initial_count = 0
  let initial_bought = []
  let initial_acc = #(initial_count, initial_bought)

  let #(_count, bought) =
    costs
    // Sort descending so the highest-value candy in each group of three is free.
    |> list.sort(by: fn(c1, c2) { c2 |> int.compare(c1) })
    |> list.fold(from: initial_acc, with: fn(acc, cost) {
      let #(count, bought) = acc

      case count == 2 {
        // Third candy in the group: take it for free (skip adding its cost).
        True -> #(0, bought)
        // First or second in the group: pay for it.
        False -> #(count + 1, [cost, ..bought])
      }
    })

  bought |> list.fold(from: 0, with: fn(total, cost) { total + cost })
}

pub fn run() {
  let c1 = [1, 2, 3]
  // 5
  echo minimum_cost(c1)

  let c2 = [6, 5, 7, 9, 2, 2]
  // 23
  echo minimum_cost(c2)

  let c3 = [5, 5]
  // 10
  echo minimum_cost(c3)
}
