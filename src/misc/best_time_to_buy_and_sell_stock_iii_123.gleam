import gleam/int

// Recursively finds the maximum profit from at most 2 transactions
// Parameters:
// - buy1: Minimum price seen so far (best price to buy first stock)
// - sell1: Maximum profit from first transaction
// - buy2: Net cost of buying second stock (price - profit from first transaction)
// - sell2: Maximum profit from both transactions combined
// - stack: Remaining prices to process
fn find_best_time(
  buy1: Int,
  sell1: Int,
  buy2: Int,
  sell2: Int,
  stack: List(Int),
) {
  case stack {
    // Base case: no more prices, return total profit from both transactions
    [] -> sell2

    [curr_price, ..rest_prices] -> {
      // Track the minimum price for first buy
      let new_buy1 = int.min(buy1, curr_price)
      // Calculate max profit from selling first stock at current price
      let new_sell1 = int.max(sell1, curr_price - new_buy1)
      // Calculate the net cost of second buy (after deducting first transaction profit)
      let new_buy2 = int.min(buy2, curr_price - new_sell1)
      // Calculate max profit from selling second stock at current price
      let new_sell2 = int.max(sell2, curr_price - new_buy2)

      find_best_time(new_buy1, new_sell1, new_buy2, new_sell2, rest_prices)
    }
  }
}

// T(n) = O(n)
// S(n) = O(1)
fn trade(prices: List(Int)) {
  find_best_time(999_999_999, 0, 999_999_999, 0, prices)
}

pub fn run() {
  let p1 = [3, 3, 5, 0, 0, 3, 1, 4]
  // 6
  echo trade(p1)

  let p2 = [1, 2, 3, 4, 5]
  // 4
  echo trade(p2)

  let p3 = [7, 6, 4, 3, 1]
  // 0
  echo trade(p3)
}
