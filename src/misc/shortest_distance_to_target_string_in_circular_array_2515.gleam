import gleam/int
import gleam/list

// Returns the shortest circular distance from start_index to any occurrence
// of target in words.
//
// Distance model:
// - Forward distance: move right with wrap-around.
// - Backward distance: move left with wrap-around.
// - For each matching index, take min(forward, backward), then keep global min.
//
// Complexity:
// - Time: O(n), where n is list length (single scan).
// - Extra space: O(1).
//
// Returns -1 when target does not exist in words.
fn shortest(words: List(String), target: String, start_index: Int) {
  let length = list.length(words)

  let best_distance =
    words
    |> list.index_fold(from: length, with: fn(distance, word, index) {
      case word == target {
        True -> {
          let forward_distance = { index - start_index + length } % length
          let backward_distance = { start_index - index + length } % length
          int.min(distance, int.min(forward_distance, backward_distance))
        }

        False -> distance
      }
    })

  case best_distance == length {
    True -> -1
    False -> best_distance
  }
}

// Smoke tests covering samples, edge cases, and wrap-around behavior.
// Each expected value is listed above its corresponding output.
pub fn run() {
  let w1 = ["hello", "i", "am", "leetcode", "hello"]
  let t1 = "hello"
  let si1 = 1
  // expected: 1
  echo shortest(w1, t1, si1)

  let w2 = ["a", "b", "leetcode"]
  let t2 = "leetcode"
  let si2 = 0
  // expected: 1
  echo shortest(w2, t2, si2)

  let w3 = ["x", "y", "z", "x"]
  let t3 = "x"
  let si3 = 0
  // expected: 0 (start index already matches)
  echo shortest(w3, t3, si3)

  let w4 = ["a", "b", "c", "d"]
  let t4 = "c"
  let si4 = 1
  // expected: 1
  echo shortest(w4, t4, si4)

  let w5 = ["a", "b", "c", "d"]
  let t5 = "c"
  let si5 = 3
  // expected: 1 (wrap-around backward)
  echo shortest(w5, t5, si5)

  let w6 = ["same", "same", "same", "same"]
  let t6 = "same"
  let si6 = 2
  // expected: 0
  echo shortest(w6, t6, si6)

  let w7 = ["a", "b", "a", "b", "a"]
  let t7 = "a"
  let si7 = 3
  // expected: 1 (nearest a at index 2 or 4)
  echo shortest(w7, t7, si7)

  let w8 = ["target"]
  let t8 = "target"
  let si8 = 0
  // expected: 0
  echo shortest(w8, t8, si8)

  let w9 = ["only"]
  let t9 = "missing"
  let si9 = 0
  // expected: -1
  echo shortest(w9, t9, si9)

  let w10 = ["a", "b", "c", "d", "e", "f"]
  let t10 = "a"
  let si10 = 4
  // expected: 2 (to index 0 via forward wrap)
  echo shortest(w10, t10, si10)

  let w11 = ["red", "blue", "green", "yellow"]
  let t11 = "purple"
  let si11 = 2
  // expected: -1 (target absent)
  echo shortest(w11, t11, si11)
}
