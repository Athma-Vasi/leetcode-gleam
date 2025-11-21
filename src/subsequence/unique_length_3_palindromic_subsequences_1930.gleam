import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string

// Build a dictionary from grapheme -> all indices where it occurs
fn create_occurrences(str: String) -> dict.Dict(String, List(Int)) {
  str
  |> string.to_graphemes
  |> list.index_fold(from: dict.new(), with: fn(acc, grapheme, index) {
    acc
    |> dict.upsert(update: grapheme, with: fn(indexes_maybe) {
      case indexes_maybe {
        option.None -> [index]
        option.Some(indexes) -> indexes |> list.append([index])
      }
    })
  })
}

// For each grapheme, count the number of unique middle graphemes between
// its first and last positions, and sum these counts.
fn process_graphemes(occurrences: dict.Dict(String, List(Int)), str: String) {
  occurrences
  |> dict.fold(from: 0, with: fn(acc, _grapheme, indexes) {
    case list.length(indexes) <= 1 {
      // Fewer than two occurrences can't form X _ X
      True -> acc
      False -> {
        let start = indexes |> list.first |> result.unwrap(or: -1)
        let end = indexes |> list.last |> result.unwrap(or: -1)

        case end - start <= 1 {
          // No room for a middle grapheme
          True -> acc
          False -> {
            // Extract strictly-between slice: (start, end)
            let middle =
              str
              |> string.to_graphemes
              |> list.drop(start + 1)
              |> list.take(end - start - 1)

            let unique_count =
              middle
              |> set.from_list
              |> set.size

            acc + unique_count
          }
        }
      }
    }
  })
}

// T(n) = O(n)
// S(n) = O(1) - max size is 26 alphabets
fn t(str: String) {
  create_occurrences(str) |> process_graphemes(str)
}

pub fn run() {
  let s1 = "aabca"
  // 3
  echo t(s1)

  let s2 = "adc"
  // 0
  echo t(s2)

  let s3 = "bbcbaba"
  // 4
  echo t(s3)
}
