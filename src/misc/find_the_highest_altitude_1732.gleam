import gleam/int
import gleam/list

// Computes all reached altitudes starting from 0 after each gain step.
// Time: O(n), where n is the number of gain values.
// Space: O(n) for the accumulated altitude list.
fn find_altitudes(gains: List(Int)) {
  let initial_prev_altitude = 0
  let initial_altitudes = [initial_prev_altitude]
  let initial_acc = #(initial_prev_altitude, initial_altitudes)

  let #(_prev_altitude, altitudes) =
    gains
    |> list.fold(from: initial_acc, with: fn(acc, gain) {
      let #(prev_altitude, altitudes) = acc
      let curr_altitude = prev_altitude + gain

      #(curr_altitude, [curr_altitude, ..altitudes])
    })

  altitudes
}

fn find_highest(altitudes: List(Int)) {
  // 32-bit signed integer minimum sentinel.
  let smallest_altitude = -2_147_483_648

  // Scans the altitude list to find the maximum reached altitude.
  // Time: O(n), where n is the number of altitudes.
  // Space: O(1) additional space.
  altitudes
  |> list.fold(from: smallest_altitude, with: fn(highest_altitude, altitude) {
    int.max(highest_altitude, altitude)
  })
}

// Returns the highest altitude reached over the trip.
// Overall complexity: Time O(n), Space O(n).
fn t(gains: List(Int)) {
  gains |> find_altitudes |> find_highest
}

pub fn run() {
  let g1 = [-5, 1, 5, 0, -7]
  // 1
  echo t(g1)

  let g2 = [-4, -3, -2, -1, 4, 3, 2]
  // 0
  echo t(g2)
}
