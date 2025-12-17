import gleam/option

// Recursively finds the maximum profit from buying and selling stock multiple times
// Parameters:
// - prev_price_maybe: Tracks the previous price (buy price for current transaction)
// - max_profit: The cumulative profit from all transactions so far
// - stack: Remaining prices to process
fn find_best_time(
  prev_price_maybe: option.Option(Int),
  max_profit: Int,
  stack: List(Int),
) {
  case stack {
    // Base case: no more prices to process, return the total profit
    [] -> max_profit

    [curr_price, ..rest_prices] -> {
      case prev_price_maybe {
        // First price: set it as the initial buy price
        option.None ->
          find_best_time(option.Some(curr_price), max_profit, rest_prices)

        option.Some(prev_price) -> {
          // Calculate profit if we sell at current price
          let profit = curr_price - prev_price

          case profit <= 0 {
            // Non-profitable: update to new buy price, keep profit unchanged
            True ->
              find_best_time(option.Some(curr_price), max_profit, rest_prices)
            // Profitable: complete transaction and use current price as next buy price
            False ->
              find_best_time(
                option.Some(curr_price),
                max_profit + profit,
                rest_prices,
              )
          }
        }
      }
    }
  }
}

// T(n) = O(n)
// S(n) = O(1)
fn trade(prices: List(Int)) {
  find_best_time(option.None, 0, prices)
}

pub fn run() {
  let p1 = [7, 1, 5, 3, 6, 4]
  // 7
  echo trade(p1)

  let p2 = [1, 2, 3, 4, 5]
  // 4
  echo trade(p2)

  let p3 = [7, 6, 4, 3, 1]
  // 0
  echo trade(p3)
}
