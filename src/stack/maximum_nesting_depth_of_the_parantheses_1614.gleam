import gleam/int
import gleam/string

fn evaluate(
  chars: List(String),
  left_parens_stack: String,
  curr_max_nesting_depth: Int,
) {
  // The stack contains unmatched opening parentheses, so its length is the
  // current depth. Time: O(n^2) worst case due to measuring its length on each
  // opening; auxiliary space: O(n) for the graphemes and stack.
  case chars {
    [] -> curr_max_nesting_depth

    [char, ..rest_chars] -> {
      case char {
        "(" -> {
          let new_left_parens_stack = char <> left_parens_stack
          evaluate(
            rest_chars,
            new_left_parens_stack,
            int.max(
              curr_max_nesting_depth,
              string.length(new_left_parens_stack),
            ),
          )
        }

        ")" ->
          evaluate(
            rest_chars,
            left_parens_stack |> string.drop_start(up_to: 1),
            curr_max_nesting_depth,
          )

        _ -> evaluate(rest_chars, left_parens_stack, curr_max_nesting_depth)
      }
    }
  }
}

fn t(str: String) {
  evaluate(str |> string.to_graphemes, "", 0)
}

pub fn run() {
  let s1 = "(1+(2*3)+((8)/4))+1"
  // 3
  echo t(s1)

  let s2 = "(1)+((2))+(((3)))"
  // 3
  echo t(s2)

  let s3 = "()(())((()()))"
  // 3
  echo t(s3)
}
