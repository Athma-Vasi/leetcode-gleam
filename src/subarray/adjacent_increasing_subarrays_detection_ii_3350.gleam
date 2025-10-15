import gleam/list
import gleam/result

fn detect_adjacent(indices, k, stack: List(#(Int, Int))) {
  case indices, stack {
    // end of indices
    [], [] | [], _stack -> k + 1

    // starting processing
    [first, ..rest_indices], [] -> detect_adjacent(rest_indices, k, [first])

    // processing
    [curr, ..rest_indices], [prev, ..] -> {
      let #(second_start, second_end) = curr
      let #(first_start, first_end) = prev
      let first_length = first_end - first_start
      let second_length = second_end - second_start

      case second_length == first_length {
        // adjacent; add any length as k
        True -> detect_adjacent(rest_indices, second_length, [curr])
        // not adjacent
        False -> detect_adjacent(rest_indices, k, [curr])
      }
    }
  }
}

fn detect_increasing_subarrays(
  nums: List(Int),
  curr_count: Int,
  index: Int,
  // [(start, end),..]
  indices: List(#(Int, Int)),
  mono_stack: List(Int),
) {
  case nums, mono_stack {
    // end of nums
    [], [] | [], _mono_stack -> {
      case list.length(indices) == 1 {
        // one increasing subarray 
        True -> {
          let #(start, end) =
            indices |> list.first |> result.unwrap(or: #(-1, -1))
          // split into two adjacent subarrays
          { { end + 1 } - start } / 2
        }
        // multiple increasing subarrays
        False -> detect_adjacent(indices, 0, [])
      }
    }

    // starting processing
    [curr, ..rest], [] -> {
      detect_increasing_subarrays(rest, 0, index + 1, indices, [curr])
    }

    // processing
    [curr, ..rest], mono_stack -> {
      let prev = mono_stack |> list.first |> result.unwrap(-1)

      case curr - prev == 1, curr_count == 0 {
        // increasing and continuing
        True, True | True, False -> {
          detect_increasing_subarrays(rest, curr_count + 1, index + 1, indices, [
            curr,
            ..mono_stack
          ])
        }
        // not increasing and continuing
        False, True -> {
          detect_increasing_subarrays(rest, 0, index + 1, indices, [curr])
        }
        // not increasing and not continuing
        False, False -> {
          detect_increasing_subarrays(
            rest,
            0,
            index + 1,
            indices |> list.append([#(index - { curr_count + 1 }, index - 1)]),
            [curr],
          )
        }
      }
    }
  }
}

// T(n) = O(n)
// S(n) = O(n)
fn t(nums: List(Int)) {
  detect_increasing_subarrays(nums, 0, 0, [], [])
}

pub fn run() {
  let nums1 = [2, 5, 7, 8, 9, 2, 3, 4, 3, 1]
  // 3
  echo t(nums1)

  let nums2 = [1, 2, 3, 4, 4, 4, 4, 5, 6, 7]
  // 2
  echo t(nums2)
}
