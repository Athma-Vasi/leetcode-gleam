import gleam/dict
import gleam/list
import gleam/option
import gleam/string

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

const target_word = "balloon"

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
  let sample_input_1 = "nlaebolko"
  // 1
  echo count_max_target_instances(sample_input_1)

  let sample_input_2 = "loonbalxballpoon"
  // 2
  echo count_max_target_instances(sample_input_2)

  let sample_input_3 = "leetcode"
  // 0
  echo count_max_target_instances(sample_input_3)
}
