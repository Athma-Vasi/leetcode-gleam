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
  case count == 2, nums {
    // found 2 increasing subarrays
    True, [] | True, _nums -> True
    // no more numbers to process
    False, [] -> False
    // process next number
    False, [num, ..rest] -> {
      case mono_stack {
        // start a new subarray
        [] -> detect_increasing_subarrays(count, [num], rest, k)
        mono_stack -> {
          let prev = mono_stack |> list.first |> result.unwrap(-1)

          case num - prev == 1, list.length(mono_stack) + 1 == k {
            // found an increasing subarray
            True, True -> detect_increasing_subarrays(count + 1, [], rest, k)
            // continue the current increasing subarray
            True, False ->
              detect_increasing_subarrays(count, [num, ..mono_stack], rest, k)
            // reset the current increasing subarray
            False, True | False, False ->
              detect_increasing_subarrays(count, [num], rest, k)
          }
        }
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
