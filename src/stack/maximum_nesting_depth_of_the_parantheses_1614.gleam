import gleam/int
import gleam/string

// Track the current and maximum depth while scanning the graphemes. Repeated
// concatenation can copy the growing stack string, so worst-case time is O(n^2);
// the grapheme list and stack string use O(n) auxiliary space.
fn evaluate(
  chars: List(String),
  left_parens_stack: String,
  curr_max_nesting_depth: Int,
  curr_nesting_depth: Int,
) {
  case chars {
    [] -> curr_max_nesting_depth

    [char, ..rest_chars] -> {
      case char {
        "(" ->
          evaluate(
            rest_chars,
            char <> left_parens_stack,
            int.max(curr_max_nesting_depth, curr_nesting_depth + 1),
            curr_nesting_depth + 1,
          )

        ")" ->
          evaluate(
            rest_chars,
            left_parens_stack |> string.drop_start(up_to: 1),
            curr_max_nesting_depth,
            curr_nesting_depth - 1,
          )

        _ ->
          evaluate(
            rest_chars,
            left_parens_stack,
            curr_max_nesting_depth,
            curr_nesting_depth,
          )
      }
    }
  }
}

fn t(str: String) {
  evaluate(str |> string.to_graphemes, "", 0, 0)
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
