import gleam/dict
import gleam/list
import gleam/option
import gleam/string

fn create_freq_table(text: String) {
  text
  |> string.to_graphemes
  |> list.fold(from: dict.new(), with: fn(table, grapheme) {
    table
    |> dict.upsert(update: grapheme, with: fn(freq_maybe) {
      case freq_maybe {
        option.None -> 1
        option.Some(freq) -> freq + 1
      }
    })
  })
}

const balloons = "balloon"

fn is_instance_possible(
  freq_table: dict.Dict(String, Int),
  target: List(String),
) {
  case target {
    [] -> #(True, freq_table)

    [char, ..rest_target] -> {
      case freq_table |> dict.get(char) {
        Error(Nil) -> #(False, freq_table)

        Ok(freq) -> {
          case freq == 0 {
            True -> #(False, freq_table)

            False -> {
              let updated_table =
                freq_table
                |> dict.upsert(update: char, with: fn(freq_maybe) {
                  case freq_maybe {
                    option.None -> 0
                    option.Some(freq) -> freq - 1
                  }
                })

              is_instance_possible(updated_table, rest_target)
            }
          }
        }
      }
    }
  }
}

fn repeat_balloons(repeated: List(String), factor: Int) {
  case factor == 0 {
    True -> repeated
    False -> repeat_balloons([balloons, ..repeated], factor - 1)
  }
}

fn find_maximum_balloons(text: String) {
  let length = string.length(text)
  let factor = length / string.length(balloons)
  let repeated = repeat_balloons([], factor)
  let freq_table = create_freq_table(text)

  let #(instances, _updated_table) =
    repeated
    |> list.fold(from: #(0, freq_table), with: fn(acc, target) {
      let #(instances, freq_table) = acc
      let #(is_possible, updated_table) =
        is_instance_possible(freq_table, target |> string.to_graphemes)

      case is_possible {
        True -> #(instances + 1, updated_table)
        False -> #(instances, updated_table)
      }
    })

  instances
}

pub fn run() {
  let t1 = "nlaebolko"
  // 1
  echo find_maximum_balloons(t1)

  let t2 = "loonbalxballpoon"
  // 2
  echo find_maximum_balloons(t2)

  let t3 = "leetcode"
  // 0
  echo find_maximum_balloons(t3)
}
