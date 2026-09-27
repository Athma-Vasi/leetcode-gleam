import gleam/dict
import gleam/int
import gleam/list
import gleam/string

// Enumerate every ordered choice of three distinct input positions.
// Valid numbers are stored in a dictionary so duplicate constructions count once.
// T(n) = O(n^3), S(n) = O(k), where k is the number of unique results.
fn count_uniques(digits: List(Int)) {
  digits
  |> list.index_fold(
    from: dict.new(),
    with: fn(uniques, left_digit, left_position) {
      digits
      |> list.index_fold(
        from: uniques,
        with: fn(uniques, middle_digit, middle_position) {
          digits
          |> list.index_fold(
            from: uniques,
            with: fn(uniques, right_digit, right_position) {
              // Each digit occurrence may be used at most once.
              case
                left_position == middle_position
                || left_position == right_position
                || middle_position == right_position
              {
                True -> uniques

                False -> {
                  let concatenated =
                    { left_digit * 100 } + { middle_digit * 10 } + right_digit
                  // A leading zero creates a two-digit value and is rejected.
                  let is_two_digit =
                    string.length(int.to_string(concatenated)) < 3

                  // Keep only three-digit even numbers.
                  case int.is_even(concatenated), is_two_digit {
                    True, True | False, True | False, False -> uniques

                    True, False ->
                      uniques |> dict.insert(for: concatenated, insert: [])
                  }
                }
              }
            },
          )
        },
      )
    },
  )
  |> dict.size
}

pub fn run() {
  let d1 = [1, 2, 3, 4]
  // 12
  echo count_uniques(d1)

  let d2 = [0, 2, 2]
  // 2
  echo count_uniques(d2)

  let d3 = [0, 0, 0]
  // 0
  echo count_uniques(d3)

  let d4 = [2, 2, 8, 8, 2]
  // 7
  echo count_uniques(d4)

  let d5 = [0, 1, 2, 3, 4]
  // 30
  echo count_uniques(d5)
}
