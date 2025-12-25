import gleam/int
import gleam/list

// Recursively selects k children from the sorted happiness list.
// Each selected child's happiness is reduced by their selection order (penalty).
// Returns a list of adjusted happiness values.
fn collect_maximums(
  happiness: List(Int),
  k: Int,
  penalty: Int,
  result: List(Int),
) {
  case happiness, penalty == k {
    // Base cases: empty list or we've selected k children
    [], True | [], False | _happiness, True -> result

    // Recursive case: pick the next child, apply penalty, continue
    [happy, ..rest_happiness], False ->
      collect_maximums(rest_happiness, k, penalty + 1, [
        happy - penalty,
        ..result
      ])
  }
}

// Sums all adjusted happiness values.
fn sum_maximums(maximums: List(Int)) -> Int {
  maximums |> list.fold(from: 0, with: fn(sum, maximum) { sum + maximum })
}

// Sorts happiness values in descending order (greedy: pick happiest first).
fn sort_descending(happiness: List(Int)) -> List(Int) {
  happiness
  |> list.sort(by: fn(h1, h2) { int.compare(h2, h1) })
}

// Maximizes total happiness by selecting k children with diminishing returns.
// Strategy: Sort descending, pick top k, apply i-th penalty to i-th selection.
// T(n) = O(n * log(n)) - dominated by sorting
// S(n, k) = O(k) - result list size
fn maximize_happiness(happiness: List(Int), k: Int) -> Int {
  sort_descending(happiness) |> collect_maximums(k, 0, []) |> sum_maximums
}

pub fn run() {
  let h1 = [1, 2, 3]
  let k1 = 2
  // 4
  echo maximize_happiness(h1, k1)

  let h2 = [1, 1, 1, 1]
  let k2 = 2
  // 1
  echo maximize_happiness(h2, k2)

  let h3 = [2, 3, 4, 5]
  let k3 = 1
  // 5
  echo maximize_happiness(h3, k3)
}
