import gleam/int
import gleam/list
import gleam/string

// Stores character indices used to determine the start of a valid suffix
// ending at the current character.
fn evaluate(
  chars: List(String),
  indices_stack: List(Int),
  max_length: Int,
  index: Int,
) {
  case chars {
    [] -> max_length

    [char, ..rest_chars] ->
      case char {
        // Save the index so a later closing parenthesis can match this one.
        "(" ->
          evaluate(rest_chars, [index, ..indices_stack], max_length, index + 1)

        // Remove the most recent saved index to account for this closing
        // parenthesis.
        _ -> {
          let popped_indices_stack = indices_stack |> list.drop(up_to: 1)

          case popped_indices_stack {
            // No earlier index remains, so this position becomes a new
            // boundary for subsequent valid substrings.
            [] ->
              evaluate(
                rest_chars,
                [index, ..indices_stack],
                max_length,
                index + 1,
              )

            // The new stack top is the boundary before the valid suffix.
            [new_top, ..] ->
              evaluate(
                rest_chars,
                popped_indices_stack,
                int.max(max_length, index - new_top),
                index + 1,
              )
          }
        }
      }
  }
}

pub fn run() {
  let s1 = "(()"
  // Expected: 2
  echo evaluate(s1 |> string.to_graphemes, [], 0, 0)

  let s2 = ")()())"
  // Expected: 4
  echo evaluate(s2 |> string.to_graphemes, [], 0, 0)

  let s3 = ""
  // Expected: 0
  echo evaluate(s3 |> string.to_graphemes, [], 0, 0)
}
