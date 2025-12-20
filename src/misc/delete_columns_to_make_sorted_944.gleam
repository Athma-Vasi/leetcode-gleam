import gleam/dict
import gleam/list
import gleam/option
import gleam/order
import gleam/string

// Build columns by accumulating graphemes at each position into strings
fn make_columns_table(strings: List(String)) -> dict.Dict(Int, String) {
  strings
  |> list.fold(from: dict.new(), with: fn(columns_acc, string) {
    string
    |> string.to_graphemes
    |> list.index_fold(
      from: columns_acc,
      with: fn(columns_acc, grapheme, index) {
        columns_acc
        |> dict.upsert(update: index, with: fn(column_maybe) {
          case column_maybe {
            option.None -> grapheme
            option.Some(column) -> column |> string.append(suffix: grapheme)
          }
        })
      },
    )
  })
}

// Extract column strings from the table as a list
fn make_column_strings(columns_table: dict.Dict(Int, String)) -> List(String) {
  columns_table
  |> dict.to_list
  |> list.fold(from: [], with: fn(strings_acc, tuple) {
    let #(_index, string) = tuple
    strings_acc |> list.append([string])
  })
}

// Check if a column string is sorted in lexicographic (ascending) order
fn check_if_sorted(string: String) {
  let #(is_sorted, _prev_grapheme) =
    string
    |> string.to_graphemes
    |> list.fold(from: #(True, ""), with: fn(acc, grapheme) {
      let #(is_sorted, prev_grapheme) = acc

      case string.compare(prev_grapheme, grapheme) {
        order.Eq | order.Lt -> #(is_sorted, grapheme)

        order.Gt -> #(False, grapheme)
      }
    })

  is_sorted
}

// Count columns that are NOT lexicographically sorted (candidates for deletion)
fn count_lexicographically_unsorted(strings: List(String)) -> Int {
  strings
  |> list.fold(from: 0, with: fn(count, string) {
    let is_sorted = check_if_sorted(string)
    case is_sorted {
      True -> count
      False -> count + 1
    }
  })
}

// T(n) = O(n * m) where n = num strings, m = string length
// S(n) = O(n * m) for the columns table
fn t(strings: List(String)) {
  make_columns_table(strings)
  |> make_column_strings
  |> count_lexicographically_unsorted
}

pub fn run() {
  let s1 = ["cba", "daf", "ghi"]
  // 1
  echo t(s1)

  let s2 = ["a", "b"]
  // 0
  echo t(s2)

  let s3 = ["zyx", "wvu", "tsr"]
  // 3
  echo t(s3)
}
