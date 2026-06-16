import gleam/list

// Traverses two aligned lists and tracks the maximum pair sum encountered.
//
// Complexity for this helper:
// - Time: O(n), where n is the number of pairs scanned.
// - Extra space: O(1), excluding call-stack optimizations from tail recursion.
fn traverse(
  max_twin_sum: Int,
  forward_list: List(Int),
  reverse_list: List(Int),
) {
  case forward_list, reverse_list {
    [], [] | [], _ | _, [] -> max_twin_sum

    [forward_num, ..rest_forward_list], [reverse_num, ..rest_reverse_list] ->
      case max_twin_sum < forward_num + reverse_num {
        True ->
          traverse(
            forward_num + reverse_num,
            rest_forward_list,
            rest_reverse_list,
          )

        False -> traverse(max_twin_sum, rest_forward_list, rest_reverse_list)
      }
  }
}

// Computes the maximum twin sum for a list representing an even-length linked list.
// Twin indices are mirrored around the center: i and (n - 1 - i).
//
// Overall complexity:
// - Time: O(n) for reverse + O(n) for scan = O(n)
// - Extra space: O(n) for the reversed copy
fn pair_sum_max(values: List(Int)) {
  case values, list.reverse(values) {
    [left, ..rest_left], [right, ..rest_right] ->
      traverse(left + right, rest_left, rest_right)

    _, _ -> 0
  }
}

// Comprehensive smoke tests.
// Each expected value is documented beside the corresponding input.
pub fn run() {
  let l1 = [5, 4, 2, 1]
  // expected: 6
  echo pair_sum_max(l1)

  let l2 = [4, 2, 2, 3]
  // expected: 7
  echo pair_sum_max(l2)

  let l3 = [1, 100_000]
  // expected: 100001
  echo pair_sum_max(l3)

  let l4 = [1, 2, 3, 4]
  // expected: 5
  echo pair_sum_max(l4)

  let l5 = [9, 1, 2, 8]
  // expected: 17
  echo pair_sum_max(l5)

  let l6 = [10, 10, 10, 10]
  // expected: 20
  echo pair_sum_max(l6)

  let l7 = [1, 2, 100, 99, 3, 4]
  // expected: 103
  echo pair_sum_max(l7)

  let l8 = [0, 5]
  // expected: 5
  echo pair_sum_max(l8)

  let l9 = [1, 100, 2, 99, 3, 98, 4, 97]
  // expected: 197
  echo pair_sum_max(l9)

  let l10 = [50, 1, 1, 50]
  // expected: 100
  echo pair_sum_max(l10)

  let l11 = [0, 0, 0, 0, 0, 0]
  // expected: 0
  echo pair_sum_max(l11)

  let l12 = []
  // expected: 0 (defensive fallback)
  echo pair_sum_max(l12)
}
