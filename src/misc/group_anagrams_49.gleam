import gleam/dict
import gleam/list
import gleam/option
import gleam/string

fn sum_codepoints(word: String) {
  word
  |> string.to_utf_codepoints
  |> list.fold(from: 0, with: fn(sum_acc, codepoint) {
    sum_acc + string.utf_codepoint_to_int(codepoint)
  })
}

fn grab_grouped_anagrams(
  table: dict.Dict(Int, List(String)),
) -> List(List(String)) {
  table
  |> dict.to_list
  |> list.fold(from: [], with: fn(grouped_acc, tuple) {
    let #(_coordinates_sum, anagrams) = tuple
    [anagrams, ..grouped_acc]
  })
}

fn create_codepoints_table(words: List(String)) {
  words
  |> list.fold(from: dict.new(), with: fn(acc, word) {
    let codepoints_sum = sum_codepoints(word)

    acc
    |> dict.upsert(update: codepoints_sum, with: fn(anagrams_maybe) {
      case anagrams_maybe {
        option.None -> [word]
        option.Some(anagrams) -> [word, ..anagrams]
      }
    })
  })
}

// T(n) = O(n)
// S(n) = O(n)
fn group_anagrams(words: List(String)) {
  create_codepoints_table(words) |> grab_grouped_anagrams
}

pub fn run() {
  let s1 = ["act", "pots", "tops", "cat", "stop", "hat"]
  echo group_anagrams(s1)

  let s2 = ["x"]
  echo group_anagrams(s2)

  let s3 = [""]
  echo group_anagrams(s3)
}
