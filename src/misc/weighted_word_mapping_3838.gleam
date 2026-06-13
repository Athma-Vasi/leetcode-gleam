import gleam/dict
import gleam/list
import gleam/string

// Builds two lookup tables:
// 1) alphabet -> weight
// 2) modulo index (0..25) -> alphabet in reverse order (0 -> z, 1 -> y, ...)
// Time: O(26)
// Space: O(26)
fn build_lookup_tables(
  weights: List(Int),
) -> #(dict.Dict(String, Int), dict.Dict(Int, String)) {
  let alphabet_chars = [
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z",
  ]

  let char_weight_map =
    alphabet_chars
    |> list.zip(with: weights)
    |> list.fold(from: dict.new(), with: fn(table, tuple) {
      let #(alphabet, weight) = tuple
      table |> dict.insert(for: alphabet, insert: weight)
    })

  let reverse_index_to_char_map =
    alphabet_chars
    |> list.reverse
    |> list.index_fold(from: dict.new(), with: fn(table, alphabet, index) {
      table |> dict.insert(for: index, insert: alphabet)
    })

  #(char_weight_map, reverse_index_to_char_map)
}

// Maps each word to a single character by:
// - summing weights of its characters,
// - taking modulo 26,
// - resolving through the reverse alphabet table,
// then concatenating all mapped characters into the final string.
//
// Let n = number of words, and L = total number of characters across all words.
// Time: O(L + n) (plus O(26) table setup)
// Space: O(26) auxiliary, excluding output
fn encode_weighted_words(words: List(String), weights: List(Int)) {
  let #(char_weight_map, reverse_index_to_char_map) =
    build_lookup_tables(weights)

  words
  |> list.fold(from: "", with: fn(encoded_result, current_word) {
    // Per word, compute weighted character sum in O(length(word)).
    let word_weight_sum =
      current_word
      |> string.to_graphemes
      |> list.fold(from: 0, with: fn(sum, char) {
        case char_weight_map |> dict.get(char) {
          Error(Nil) -> sum
          Ok(weight) -> sum + weight
        }
      })

    let mod_index = word_weight_sum % 26

    case reverse_index_to_char_map |> dict.get(mod_index) {
      Error(Nil) -> encoded_result
      Ok(mapped_char) -> encoded_result |> string.append(mapped_char)
    }
  })
}

pub fn run() {
  let words1 = ["abcd", "def", "xyz"]
  let weights1 = [
    5,
    3,
    12,
    14,
    1,
    2,
    3,
    2,
    10,
    6,
    6,
    9,
    7,
    8,
    7,
    10,
    8,
    9,
    6,
    9,
    9,
    8,
    3,
    7,
    7,
    2,
  ]
  // "rij"
  echo encode_weighted_words(words1, weights1)

  let words2 = ["a", "b", "c"]
  let weights2 = [
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
  ]
  // "yyy"
  echo encode_weighted_words(words2, weights2)

  let words3 = ["abcd"]
  let weights3 = [
    7,
    5,
    3,
    4,
    3,
    5,
    4,
    9,
    4,
    2,
    2,
    7,
    10,
    2,
    5,
    10,
    6,
    1,
    2,
    2,
    4,
    1,
    3,
    4,
    4,
    5,
  ]
  // "g"
  echo encode_weighted_words(words3, weights3)
}
