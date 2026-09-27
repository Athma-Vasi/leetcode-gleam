import gleam/dict
import gleam/list
import gleam/string

// Build the reverse alphabet mapping: a = 26, b = 25, ..., z = 1.
fn create_reversed_table() -> dict.Dict(String, Int) {
  let alphabet = "abcdefghijklmnopqrstuvwxyz"
  let length = string.length(alphabet)

  alphabet
  |> string.to_graphemes
  |> list.index_fold(from: dict.new(), with: fn(table, char, index) {
    table |> dict.insert(for: char, insert: length - index)
  })
}

// Sum each character's reverse value multiplied by its 1-based position.
// Characters outside the alphabet do not contribute to the degree.
// T(n) = O(n)
// S(n) = O(n)
fn calculate_reverse_degree(
  reversed_table: dict.Dict(String, Int),
  graphemes: List(String),
) -> Int {
  graphemes
  |> list.index_fold(from: 0, with: fn(reverse_degree, char, index) {
    case reversed_table |> dict.get(char) {
      Error(Nil) -> reverse_degree
      Ok(reversed_position) ->
        reverse_degree + { reversed_position * { index + 1 } }
    }
  })
}

fn t(s: String) -> Int {
  // Convert the input to graphemes before applying positional weights.
  create_reversed_table() |> calculate_reverse_degree(s |> string.to_graphemes)
}

pub fn run() {
  let s1 = "abc"
  // 148
  echo t(s1)

  let s2 = "zaza"
  // 160
  echo t(s2)
}
