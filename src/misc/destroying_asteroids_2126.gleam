import gleam/int
import gleam/list

// Greedy approach: absorb asteroids in nondecreasing order of size.
// Time: O(n log n) for sorting + O(n) fold. Space: O(n) due to sort output.
fn armageddon(mass: Int, asteroids: List(Int)) {
  let mass_after_impacts =
    asteroids
    // Sorting smallest-first maximizes the chance of successful absorption.
    |> list.sort(by: fn(asteroid1, asteroid2) {
      asteroid1 |> int.compare(asteroid2)
    })
    // Fold tracks the current planet mass after each collision.
    |> list.fold(from: mass, with: fn(terra, asteroid) {
      case asteroid < terra {
        True -> terra + asteroid
        False -> terra - asteroid
      }
    })
  mass_after_impacts > 0
}

pub fn run() {
  // Example 1: expected successful destruction sequence.
  let m1 = 10
  let a1 = [3, 9, 19, 5, 21]
  // true
  echo armageddon(m1, a1)

  // Example 2: expected failure during the sequence.
  let m2 = 5
  let a2 = [4, 9, 23, 4]
  // false
  echo armageddon(m2, a2)
}
