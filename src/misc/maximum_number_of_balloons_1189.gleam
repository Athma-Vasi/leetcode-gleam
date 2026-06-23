import gleam/dict
import gleam/list
import gleam/option
import gleam/string

const target_word = "balloon"

// Builds a frequency map of characters in the input text.
// Time: O(n * d), where n is input length and d is dictionary update cost.
// Space: O(u), where u is the number of distinct characters.
fn build_char_frequency_map(input_text: String) {
  input_text
  |> string.to_graphemes
  |> list.fold(from: dict.new(), with: fn(frequency_map, char) {
    frequency_map
    |> dict.upsert(update: char, with: fn(existing_freq_opt) {
      case existing_freq_opt {
        option.None -> 1
        option.Some(count) -> count + 1
      }
    })
  })
}

// Attempts to consume exactly one target instance from the remaining frequency map.
// Returns whether consumption was possible and the updated map state.
// Time: O(k * d), where k is target length and d is dictionary lookup/update cost.
// Space: O(k) due to recursion depth.
fn try_consume_target_once(
  remaining_frequency_map: dict.Dict(String, Int),
  target_chars: List(String),
) {
  case target_chars {
    [] -> #(True, remaining_frequency_map)

    [required_char, ..remaining_target_chars] -> {
      case remaining_frequency_map |> dict.get(required_char) {
        Error(Nil) -> #(False, remaining_frequency_map)

        Ok(count) -> {
          case count == 0 {
            True -> #(False, remaining_frequency_map)

            False -> {
              let updated_frequency_map =
                remaining_frequency_map
                |> dict.upsert(
                  update: required_char,
                  with: fn(existing_freq_opt) {
                    case existing_freq_opt {
                      option.None -> 0
                      option.Some(count) -> count - 1
                    }
                  },
                )

              try_consume_target_once(
                updated_frequency_map,
                remaining_target_chars,
              )
            }
          }
        }
      }
    }
  }
}

// Constructs a list of target words capped by the length-based upper bound.
// This does not guarantee feasibility by character counts; it only sets a max iteration cap.
// Time: O(m), where m is max_instances_by_length.
// Space: O(m) for the list of candidate targets.
fn build_length_bound_targets(
  candidate_targets: List(String),
  max_instances_by_length: Int,
) {
  case max_instances_by_length == 0 {
    True -> candidate_targets

    False ->
      build_length_bound_targets(
        [target_word, ..candidate_targets],
        max_instances_by_length - 1,
      )
  }
}

// Counts the maximum number of target instances that can be formed from input_text.
// Strategy:
// 1) Build character frequencies.
// 2) Build a length-based upper bound list of candidate targets.
// 3) Greedily consume one target at a time while possible.
// Time: O(n * d + m * k * d), where n=input length, m=length upper bound, k=target length,
//       and d=dictionary operation cost.
// Space: O(u + m), where u is distinct character count.
fn count_max_target_instances(input_text: String) {
  let input_length = string.length(input_text)
  let max_instances_by_length = input_length / string.length(target_word)
  let candidate_targets =
    build_length_bound_targets([], max_instances_by_length)
  let frequency_map = build_char_frequency_map(input_text)

  let #(formed_instances, _updated_frequency_map) =
    candidate_targets
    |> list.fold(from: #(0, frequency_map), with: fn(state, target_word_chars) {
      let #(formed_instances, remaining_frequency_map) = state
      let #(can_form_instance, updated_frequency_map) =
        try_consume_target_once(
          remaining_frequency_map,
          target_word_chars |> string.to_graphemes,
        )

      case can_form_instance {
        True -> #(formed_instances + 1, updated_frequency_map)
        False -> #(formed_instances, updated_frequency_map)
      }
    })

  formed_instances
}

pub fn run() {
  // Example 1: expected 1
  let sample_input_1 = "nlaebolko"
  echo count_max_target_instances(sample_input_1)

  // Example 2: expected 2
  let sample_input_2 = "loonbalxballpoon"
  echo count_max_target_instances(sample_input_2)

  // Example 3: expected 0
  let sample_input_3 = "leetcode"
  echo count_max_target_instances(sample_input_3)
}
