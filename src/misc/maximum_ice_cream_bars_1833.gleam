import gleam/dict
import gleam/int
import gleam/list
import gleam/option

// Build a frequency table mapping each cost to its occurrence count.
// Time: O(n), where n is the number of costs.
// Space: O(k), where k is the number of distinct costs.
fn create_freq_table(costs: List(Int)) {
  costs
  |> list.fold(from: dict.new(), with: fn(table, cost) {
    table
    |> dict.upsert(update: cost, with: fn(freq_maybe) {
      case freq_maybe {
        option.None -> 1
        option.Some(freq) -> freq + 1
      }
    })
  })
}

fn find_max_cost(costs: List(Int)) {
  costs
  |> list.fold(from: -1, with: fn(max_cost, cost) { int.max(max_cost, cost) })
}

// Greedily buy bars from the lowest possible cost to the highest cost.
// For each cost value, buy all bars at that cost if affordable; otherwise skip.
// Time: O(m), where m is the maximum cost value scanned.
// Space: O(1) additional stack usage due to tail-call optimization.
fn buy_max_ice_cream(
  freq_table: dict.Dict(Int, Int),
  coins: Int,
  possible_cost: Int,
  max_cost: Int,
  ice_cream_count: Int,
) {
  case coins <= 0 || possible_cost > max_cost {
    True -> ice_cream_count

    False -> {
      case freq_table |> dict.get(possible_cost) {
        Error(Nil) ->
          buy_max_ice_cream(
            freq_table,
            coins,
            possible_cost + 1,
            max_cost,
            ice_cream_count,
          )

        Ok(freq) -> {
          let purchase_cost = possible_cost * freq

          case purchase_cost > coins {
            True ->
              buy_max_ice_cream(
                freq_table,
                coins,
                possible_cost + 1,
                max_cost,
                ice_cream_count,
              )

            False ->
              buy_max_ice_cream(
                freq_table,
                coins - purchase_cost,
                possible_cost + 1,
                max_cost,
                ice_cream_count + freq,
              )
          }
        }
      }
    }
  }
}

fn t(costs: List(Int), coins: Int) {
  // Overall complexity:
  // Time: O(n + m)
  //   - O(n) to build frequency table and compute maximum cost
  //   - O(m) to scan costs from 1 through max_cost
  // Space: O(k)
  //   - O(k) for the frequency table
  //   - Tail-recursive scan uses constant additional stack space
  let freq_table = create_freq_table(costs)
  let max_cost = find_max_cost(costs)
  buy_max_ice_cream(freq_table, coins, 1, max_cost, 0)
}

pub fn run() {
  let costs1 = [1, 3, 2, 4, 1]
  let coins1 = 7
  // 4
  echo t(costs1, coins1)

  let costs2 = [10, 6, 8, 7, 7, 8]
  let coins2 = 5
  // 0
  echo t(costs2, coins2)

  let costs3 = [1, 6, 3, 1, 2, 5]
  let coins3 = 20
  // 6
  echo t(costs3, coins3)
}
