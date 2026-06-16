import gleam/list

// Deletes the middle element from a list representation of a linked list.
// For even lengths, this removes the second middle element at index n / 2.
//
// Approach:
// - Compute the target middle index.
// - Rebuild the list while skipping only that index.
//
// Complexity:
// - Time: O(n), where n is the list length.
// - Extra space: O(n) for the rebuilt result list.
fn delete(nums: List(Int)) {
  let length = list.length(nums)
  let middle = length / 2

  nums
  |> list.index_fold(from: [], with: fn(acc, num, index) {
    case index == middle {
      True -> acc
      False -> [num, ..acc]
    }
  })
  |> list.reverse
}

// Smoke tests that cover sample inputs and key edge cases.
// Each expected value is documented above the corresponding call.
pub fn run() {
  let n1 = [1, 3, 4, 7, 1, 2, 6]
  // expected: [1, 3, 4, 1, 2, 6]
  echo delete(n1)

  let n2 = [1, 2, 3, 4]
  // expected: [1, 2, 4]
  echo delete(n2)

  let n3 = [2, 1]
  // expected: [2]
  echo delete(n3)

  let n4 = [42]
  // expected: []
  echo delete(n4)

  let n5 = []
  // expected: []
  echo delete(n5)

  let n6 = [1, 2, 3]
  // expected: [1, 3]
  echo delete(n6)

  let n7 = [10, 20, 30, 40, 50, 60]
  // expected: [10, 20, 30, 50, 60]
  echo delete(n7)

  let n8 = [0, -1, -2, -3, -4]
  // expected: [0, -1, -3, -4]
  echo delete(n8)

  let n9 = [7, 7, 7, 7, 7]
  // expected: [7, 7, 7, 7]
  echo delete(n9)

  let n10 = [1, 9, 8, 7, 6, 5, 4, 3]
  // expected: [1, 9, 8, 7, 5, 4, 3]
  echo delete(n10)
}
