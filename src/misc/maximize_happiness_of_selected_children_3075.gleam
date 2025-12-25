import gleam/int
import gleam/list

// Pick the next happiest child, apply the diminishing penalty, and recurse
// until we have chosen k children.
fn collect_maximums(
  happiness: List(Int),
  k: Int,
  penalty: Int,
  result: List(Int),
) {
  case penalty == k {
    True -> result
    False -> {
      let #(happy, rest_happiness) =
        happiness
        |> list.index_fold(from: #(0, []), with: fn(acc, curr, index) {
          let #(happy, rest_happiness) = acc
          case index == 0 {
            True -> #(curr, rest_happiness)
            False -> #(happy, rest_happiness |> list.append([curr]))
          }
        })

      collect_maximums(rest_happiness, k, penalty + 1, [
        happy - penalty,
        ..result
      ])
    }
  }
}

fn sum_maximums(maximums: List(Int)) -> Int {
  maximums |> list.fold(from: 0, with: fn(sum, maximum) { sum + maximum })
}

fn sort_descending(happiness: List(Int)) -> List(Int) {
  happiness
  |> list.sort(by: fn(h1, h2) { int.compare(h2, h1) })
}

// T(n) = O(n * log(n))
// S(n, k) = O(k)
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
