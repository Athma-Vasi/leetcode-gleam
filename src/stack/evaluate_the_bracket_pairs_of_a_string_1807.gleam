import gleam/dict
import gleam/string

// Replace each parenthesized key with its value from `knowledge_table`.
// `char_stack` collects the current key, while `result` stores completed text.
// T(n) = O(n)
// S(n) = O(n)
fn evaluate(
  graphemes: List(String),
  knowledge_table: dict.Dict(String, String),
  char_stack: String,
  result: String,
) {
  case graphemes {
    [] -> result <> char_stack

    [grapheme, ..rest_graphemes] ->
      case grapheme {
        // Start collecting a key and append the text seen so far to the result.
        "(" ->
          evaluate(rest_graphemes, knowledge_table, "", result <> char_stack)

        ")" ->
          // Look up the collected key; unknown keys are represented by "?".
          case knowledge_table |> dict.get(char_stack) {
            Error(Nil) ->
              evaluate(rest_graphemes, knowledge_table, "", result <> "?")

            Ok(chars) ->
              evaluate(rest_graphemes, knowledge_table, "", result <> chars)
          }

        char ->
          // Keep collecting either ordinary text or characters from a key.
          evaluate(rest_graphemes, knowledge_table, char_stack <> char, result)
      }
  }
}

fn t(str: String, knowledge: List(#(String, String))) {
  // Convert the string into graphemes so each character can be processed.
  evaluate(str |> string.to_graphemes, knowledge |> dict.from_list, "", "")
}

pub fn run() {
  let s1 = "(name)is(age)yearsold"
  let k1 = [#("name", "bob"), #("age", "two")]
  // bobistwoyearsold
  echo t(s1, k1)

  let s2 = "hi(name)"
  let k2 = [#("a", "b")]
  // hi(name)
  echo t(s2, k2)

  let s3 = "(a)(a)(a)aaa"
  let k3 = [#("a", "yes")]
  // yesyesyesaaa
  echo t(s3, k3)
}
