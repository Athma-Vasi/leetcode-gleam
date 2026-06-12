// Two-pointer scan over two sorted lists.
// Time: O(n + m), where n and m are the lengths of nums1 and nums2.
// Space: O(1) auxiliary space (tail-recursive state only).
fn minimum_common_value(nums1: List(Int), nums2: List(Int), result: Int) {
  case nums1, nums2 {
    [], [] | [], _ | _, [] -> result

    [num1, ..rest_nums1], [num2, ..rest_nums2] ->
      case num1 < num2 {
        True -> minimum_common_value(rest_nums1, [num2, ..rest_nums2], result)

        False ->
          case num1 > num2 {
            True ->
              minimum_common_value([num1, ..rest_nums1], rest_nums2, result)

            // Lists are sorted, so the first match is the minimum common value.
            False -> num1
          }
      }
  }
}

// Returns the minimum common value between two sorted lists, or -1 if none exists.
// Time: O(n + m)
// Space: O(1)
fn t(nums1: List(Int), nums2: List(Int)) {
  minimum_common_value(nums1, nums2, -1)
}

pub fn run() {
  let n1 = [1, 2, 3]
  let n11 = [2, 4]
  // 2
  echo t(n1, n11)
  let n2 = [1, 2, 3, 6]
  let n22 = [2, 3, 4, 5]
  // 2
  echo t(n2, n22)
}
