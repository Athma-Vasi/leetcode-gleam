import gleam/string

// Reverse the half-open grapheme range [start_index, end_index) in place
// conceptually, preserving the characters on either side.
fn reverse_substring(str: String, start_index: Int, end_index: Int) {
  let left_chars = str |> string.slice(at_index: 0, length: start_index)
  let middle_chars =
    str
    |> string.slice(at_index: start_index, length: end_index - start_index)
    |> string.reverse
  let right_chars =
    str
    |> string.slice(at_index: end_index, length: string.length(str) - end_index)

  left_chars <> middle_chars <> right_chars
}

fn remove_parentheses(str: String) {
  str
  |> string.replace(each: "(", with: "")
  |> string.replace(each: ")", with: "")
}

// Track unmatched opening-parenthesis indices and reverse each matched range
// while keeping delimiters until the scan completes. Rebuilding the string for
// each pair gives O(n^2) worst-case time; the grapheme list and working strings
// require O(n) auxiliary space.
fn reverse_substrings(
  chars: List(String),
  index: Int,
  paren_index_tuples_stack: List(#(String, Int)),
  curr_reversed: String,
) {
  case chars {
    [] -> curr_reversed |> remove_parentheses

    [char, ..rest_chars] -> {
      case char, paren_index_tuples_stack {
        "(", _ ->
          reverse_substrings(
            rest_chars,
            index + 1,
            [#(char, index), ..paren_index_tuples_stack],
            curr_reversed,
          )

        ")", [] ->
          reverse_substrings(
            rest_chars,
            index + 1,
            paren_index_tuples_stack,
            curr_reversed,
          )

        ")", [paren_index_tuple] -> {
          let #(_paren, opening_index) = paren_index_tuple

          reverse_substrings(
            rest_chars,
            index + 1,
            [],
            reverse_substring(curr_reversed, opening_index, index),
          )
        }

        ")", [paren_index_tuple, ..rest_parens_indices] -> {
          let #(_paren, opening_index) = paren_index_tuple

          reverse_substrings(
            rest_chars,
            index + 1,
            rest_parens_indices,
            reverse_substring(curr_reversed, opening_index, index),
          )
        }

        _, _ ->
          reverse_substrings(
            rest_chars,
            index + 1,
            paren_index_tuples_stack,
            curr_reversed,
          )
      }
    }
  }
}

fn t(str: String) {
  reverse_substrings(str |> string.to_graphemes, 0, [], str)
}

pub fn run() {
  let s1 = "(abcd)"
  // dcba
  echo t(s1)

  let s2 = "(u(love)i)"
  // iloveu
  echo t(s2)

  let s3 = "(ed(et(oc))el)"
  // leetcode
  echo t(s3)
}
