import gleam/dict
import gleam/string

// Validate parentheses using a stack.
// Algorithm:
// - Push opening brackets onto `stack`.
// - On a closing bracket, pop the top opening and check that it matches.
// - At the end, the stack should be empty for a valid string.
fn determine_validity(
  validity: Bool,
  stack: List(String),
  table: dict.Dict(String, String),
  graphemes: List(String),
) -> Bool {
  // Pattern-match both remaining input (`graphemes`) and current `stack`
  case graphemes, stack {
    // End of input: returns current validity 
    [], [] -> validity

    // Finished processing string. There were unmatched openings.
    [], _non_empty_stack -> False

    // First character with empty stack: push it and continue
    // If it's a closing bracket, this will be treated as invalid later.
    [parenthesis, ..rest_parentheses], [] ->
      determine_validity(validity, [parenthesis], table, rest_parentheses)

    [parenthesis, ..rest_parentheses], [top, ..rest_stack] -> {
      case parenthesis {
        // Opening bracket: push on top of the stack
        "(" | "{" | "[" ->
          determine_validity(
            validity,
            [parenthesis, top, ..rest_stack],
            table,
            rest_parentheses,
          )

        closing_parenthesis -> {
          // Closing bracket: stack top must correspond to the matching opening
          case table |> dict.get(closing_parenthesis) {
            Error(Nil) ->
              determine_validity(False, rest_stack, table, rest_parentheses)

            Ok(possible_match) -> {
              case possible_match == top {
                // Matching pair: pop and continue
                True ->
                  determine_validity(True, rest_stack, table, rest_parentheses)

                // Mismatch: invalid
                False ->
                  determine_validity(False, rest_stack, table, rest_parentheses)
              }
            }
          }
        }
      }
    }
  }
}

fn t(str: String) -> Bool {
  // Map of closing -> opening bracket (e.g., ")" -> "(")
  let matching_table =
    [#(")", "("), #("}", "{"), #("]", "[")]
    |> dict.from_list
  // Split the input into graphemes (characters)
  let graphemes = str |> string.to_graphemes

  // Start with validity = True and an empty stack
  determine_validity(True, [], matching_table, graphemes)
}

pub fn run() {
  let s1 = "()"
  // True
  echo t(s1)

  let s2 = "()[]{}"
  // True
  echo t(s2)

  let s3 = "(]"
  // False
  echo t(s3)

  let s4 = "([])"
  // True
  echo t(s4)

  let s5 = "([)]"
  // False
  echo t(s5)
}
