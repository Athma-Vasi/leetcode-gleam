import gleam/list
import gleam/string

type Operation {
  Asterisk
  Pound
  Percent
  Lowercase(letter: String)
}

// Applies operations from left to right and returns the transformed string.
//
// Operation rules:
// - Asterisk: remove the last character (if present)
// - Pound: duplicate the current string
// - Percent: reverse the current string
// - Lowercase: append the provided lowercase letter
//
// Complexity:
// - Let n be number of operations and L_i be the result length after step i.
// - Time: O(sum(L_i)) because duplicate/reverse scale with current string size.
// - Space: O(max(L_i)) for the largest intermediate string.
// - Worst case with repeated Pound operations is exponential growth in output size.
fn process(input: List(Operation)) {
  input
  |> list.fold(from: "", with: fn(result, operation) {
    case operation {
      Asterisk -> result |> string.drop_end(up_to: 1)
      Pound -> result |> string.append(suffix: result)
      Percent -> result |> string.reverse
      Lowercase(letter) -> result |> string.append(suffix: letter)
    }
  })
}

// Smoke tests covering normal behavior and edge cases.
// Each echo prints the computed result; compare with the expected comment.
pub fn run() {
  let t1 = [
    Lowercase("a"),
    Pound,
    Lowercase("b"),
    Percent,
    Asterisk,
  ]
  // expected: "ba"
  echo process(t1)

  let t2 = [
    Lowercase("z"),
    Asterisk,
    Pound,
  ]
  // expected: ""
  echo process(t2)

  let t3 = [
    Lowercase("a"),
    Lowercase("b"),
    Lowercase("c"),
  ]
  // expected: "abc"
  echo process(t3)

  let t4 = [Lowercase("a"), Pound]
  // expected: "aa"
  echo process(t4)

  let t5 = [Lowercase("a"), Lowercase("b"), Percent]
  // expected: "ba"
  echo process(t5)

  let t6 = [Lowercase("a"), Asterisk]
  // expected: ""
  echo process(t6)

  let t7 = [Asterisk, Lowercase("a")]
  // expected: "a"
  echo process(t7)

  let t8 = [Lowercase("a"), Pound, Pound]
  // expected: "aaaa"
  echo process(t8)

  let t9 = [Lowercase("a"), Lowercase("b"), Asterisk, Pound]
  // expected: "aa"
  echo process(t9)

  let t10 = [Lowercase("a"), Percent, Lowercase("b"), Pound]
  // expected: "abab"
  echo process(t10)
}
