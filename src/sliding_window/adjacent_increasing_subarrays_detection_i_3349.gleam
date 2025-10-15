import gleam/list
import gleam/result

// T(n) = O(n)
// S(n,k) = O(k)
fn detect_increasing_subarrays(
  count: Int,
  mono_stack: List(Int),
  nums: List(Int),
  k: Int,
) {
  count == 2
  || case nums, mono_stack {
    // finished scanning the array
    [], [] | [], _mono_stack -> False

    [curr, ..rest], mono_stack -> {
      let prev = mono_stack |> list.first |> result.unwrap(-1)

      case curr - prev == 1, list.length(mono_stack) + 1 == k {
        // found an increasing subarray
        True, True -> detect_increasing_subarrays(count + 1, [], rest, k)
        // continue the current increasing subarray
        True, False ->
          detect_increasing_subarrays(count, [curr, ..mono_stack], rest, k)
        // reset the current increasing subarray
        False, True | False, False ->
          detect_increasing_subarrays(count, [curr], rest, k)
      }
    }
  }
}

fn t(nums: List(Int), k: Int) {
  detect_increasing_subarrays(0, [], nums, k)
}

pub fn run() {
  let nums1 = [2, 5, 7, 8, 9, 2, 3, 4, 3, 1]
  let k1 = 3
  // true
  echo t(nums1, k1)

  let nums2 = [1, 2, 3, 4, 4, 4, 4, 5, 6, 7]
  let k2 = 5
  // false
  echo t(nums2, k2)
}
