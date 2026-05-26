import gleam/list
import gleam/set
import gleam/string

// Time: O(n), where n is word length. Building the set is O(n), and the
// alphabet scan is O(26), which is constant.
// Space: O(n) for the set of graphemes.
fn count(word: String) {
  let word_set = word |> string.to_graphemes |> set.from_list
  let lowercases = [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
    "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  ]

  lowercases
  |> list.fold(from: 0, with: fn(count, lowercase) {
    case
      word_set |> set.contains(lowercase),
      word_set |> set.contains(string.uppercase(lowercase))
    {
      True, True -> count + 1

      _, _ -> count
    }
  })
}

pub fn run() {
  let w1 = "aaAbcBC"
  // 3
  echo count(w1)

  let w2 = "abc"
  // 0
  echo count(w2)

  let w3 = "abBCab"
  // 1
  echo count(w3)
}
