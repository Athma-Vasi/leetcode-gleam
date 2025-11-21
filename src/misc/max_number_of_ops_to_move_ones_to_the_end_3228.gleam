import gleam/list
import gleam/option
import gleam/string

// T(n) = O(n)
// S(n, k) = O(k) where k is the maximum consecutive '1's before any '0'
fn operation(
  count: Int,
  stack: List(String),
  prev_maybe: option.Option(String),
  graphemes: List(String),
) {
  case graphemes {
    // Base case: no more characters, return total count
    [] -> count

    [first, ..rest] -> {
      case first {
        "1" -> {
          case prev_maybe {
            // First character in the string
            option.None -> {
              operation(count, [first, ..stack], option.Some(first), rest)
            }

            option.Some(prev) -> {
              case prev {
                // Transition from '0' to '1': start a new group of consecutive 1s
                "0" -> {
                  operation(count, [first], option.Some(first), rest)
                }
                // Consecutive '1': add to the current group
                _ -> {
                  operation(count, [first, ..stack], option.Some(first), rest)
                }
              }
            }
          }
        }
        // Encountered a '0'
        _ -> {
          // Each '1' in the stack needs one operation to jump over this '0'
          operation(count + list.length(stack), stack, option.Some("0"), rest)
        }
      }
    }
  }
}

// Helper function to initiate the operation with initial state
fn t(s: String) {
  operation(0, [], option.None, string.to_graphemes(s))
}

pub fn run() {
  // Example: "1001101"
  // - "1" at pos 0: stack=[1], count=0
  // - "0" at pos 1: count=1 (1 operation to move first '1' past this '0')
  // - "0" at pos 2: count=2 (1 more operation)
  // - "11" at pos 3-4: stack=[1,1], count=2 (new group of consecutive 1s)
  // - "0" at pos 5: count=4 (2 operations to move both 1s past this '0')
  // - "1" at pos 6: stays at end, no more operations needed
  // Total: 4 operations
  let s1 = "1001101"
  // 4
  echo t(s1)

  // Example: "00111"
  // All 1s are already at the end, no operations needed
  let s2 = "00111"
  // 0
  echo t(s2)
}
