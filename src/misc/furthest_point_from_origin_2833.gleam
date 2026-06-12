import gleam/int
import gleam/list

type Move {
  Left
  Right
  Wildcard
}

/// Computes the maximum possible distance from origin after interpreting
/// each `Wildcard` move in the most favorable direction.
/// Time complexity: O(n), where n is the number of moves.
/// Space complexity: O(1) extra space.
fn determine_furthest(moves: List(Move)) {
  let initial_distance = 0
  let initial_wildcards = 0
  let initial_acc = #(initial_distance, initial_wildcards)

  let #(distance, wildcards) =
    moves
    |> list.fold(from: initial_acc, with: fn(acc, move) {
      let #(distance, wildcards) = acc

      case move {
        Left -> #(distance + 1, wildcards)
        Right -> #(distance - 1, wildcards)
        Wildcard -> #(distance, wildcards + 1)
      }
    })

  int.absolute_value(distance) + wildcards
}

pub fn run() {
  let m1 = [Left, Wildcard, Right, Left, Wildcard, Wildcard, Right]
  // 3
  echo determine_furthest(m1)

  let m2 = [Wildcard, Right, Wildcard, Wildcard, Left, Left, Wildcard]
  // 5
  echo determine_furthest(m2)

  let m3 = [
    Wildcard,
    Wildcard,
    Wildcard,
    Wildcard,
    Wildcard,
    Wildcard,
    Wildcard,
  ]
  // 7
  echo determine_furthest(m3)
}
