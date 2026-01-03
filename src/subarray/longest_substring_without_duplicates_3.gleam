import gleam/int
import gleam/set
import gleam/string

// T(n) = O(n)
// S(n, k) = O(k) where k is size of uniques
fn slide_window(
  longest_uniques_size: Int,
  uniques_window: set.Set(String),
  graphemes: List(String),
) {
  // Tail-recursive sliding window over graphemes to track the longest unique span
  case graphemes {
    [] -> longest_uniques_size

    [grapheme, ..rest] ->
      case uniques_window |> set.contains(grapheme) {
        True ->
          // Duplicate hit: record best so far, restart window from this grapheme
          slide_window(
            int.max(longest_uniques_size, uniques_window |> set.size),
            set.new() |> set.insert(grapheme),
            rest,
          )

        False ->
          // Extend current window with a new unique grapheme
          slide_window(
            longest_uniques_size,
            uniques_window |> set.insert(grapheme),
            rest,
          )
      }
  }
}

fn longest_unique(str: String) {
  // Bootstrap recursion with empty window on grapheme-split string
  slide_window(0, set.new(), str |> string.to_graphemes)
}

pub fn run() {
  let s1 = "abcabcbb"
  // 3
  echo longest_unique(s1)

  let s2 = "bbbbb"
  // 1
  echo longest_unique(s2)

  let s3 = "pwwkew"
  // 3
  echo longest_unique(s3)
}
