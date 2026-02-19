import gleam/list
import gleam/option
import gleam/string

/// Counts binary substrings where consecutive groups of 0s and 1s have equal length.
/// 
/// Problem: Given a binary string, count the number of substrings where we have
/// equal consecutive groups of 0s followed by 1s, or vice versa.
/// For example, "00110011" contains substrings "0011", "01", "10", "1100", "0011", "10".
///
/// Algorithm: Single-pass fold using state machine approach.
/// - Track the previous run length (count of consecutive identical characters from previous group)
/// - Track the current run length (count of consecutive identical characters in current group)
/// - When transitioning between different characters, count a valid substring if:
///   prev_run_length >= curr_run_length
///
/// The equality condition works because: if we have 2+ of character A followed by 2+ of 
/// character B, we can always form at least one valid substring of format AABB.
///
/// Time Complexity: O(n) - Single pass through the string
/// Space Complexity: O(n) - Converting string to graphemes list; O(1) extra space for state tracking
///
fn count_substrings(str: String) {
  // Initialize accumulator state: (prev_grapheme, prev_run_length, curr_run_length, count)
  // - prev_grapheme: Previous grapheme seen (None until first iteration)
  // - prev_run_length: Length of the previously completed run of identical characters
  // - curr_run_length: Length of the current ongoing run of identical characters
  // - amount: Count of valid substrings found
  let initial_prev_grapheme_maybe = option.None
  let initial_prev_run_length = 0
  let initial_curr_run_length = 0
  let initial_amount = 0
  let initial_acc = #(
    initial_prev_grapheme_maybe,
    initial_prev_run_length,
    initial_curr_run_length,
    initial_amount,
  )

  let #(_prev_grapheme_maybe, _prev_run_length, _curr_run_length, amount) =
    str
    |> string.to_graphemes
    |> list.fold(from: initial_acc, with: fn(acc, curr_grapheme) {
      let #(prev_grapheme_maybe, prev_run_length, curr_run_length, amount) = acc

      case prev_grapheme_maybe {
        option.None -> {
          // First character: initialize the current run with length 1
          #(
            option.Some(curr_grapheme),
            prev_run_length,
            curr_run_length + 1,
            amount,
          )
        }

        option.Some(prev_grapheme) -> {
          // Character encountered: determine if we continue same run or start new one
          let #(new_prev_run_length, new_curr_run_length) = case
            prev_grapheme == curr_grapheme
          {
            True ->
              // Same character: continue current run, keep prev_run_length unchanged
              #(prev_run_length, curr_run_length + 1)
            False ->
              // Different character: transition to new run
              // The previous run (prev_run_length) is now complete
              // Start new run with length 1, and shift current to previous
              #(curr_run_length, 1)
          }

          // Count valid substring if we have equal or more chars in prev run than curr run
          // This represents valid patterns like "00" followed by "11" = "0011"
          let new_amount = case new_prev_run_length >= new_curr_run_length {
            True -> amount + 1
            False -> amount
          }

          #(
            option.Some(curr_grapheme),
            new_prev_run_length,
            new_curr_run_length,
            new_amount,
          )
        }
      }
    })

  amount
}

pub fn run() {
  // Test case 1: "00110011"
  // Valid substrings: "0011"(pos 0-3), "01"(pos 1-2), "10"(pos 2-3), 
  //                   "1100"(pos 2-5), "0011"(pos 4-7), "10"(pos 5-6)
  // Expected: 6
  let s1 = "00110011"
  echo count_substrings(s1)

  // Test case 2: "10101"
  // Valid substrings: "1010"(pos 0-3), "01"(pos 1-2), "10"(pos 2-3), "01"(pos 3-4)
  // Expected: 4
  let s2 = "10101"
  echo count_substrings(s2)
}
