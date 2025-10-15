import gleam/list
import gleam/result

// incorrect

fn detect_adjacent(indices, k, stack: List(#(Int, Int))) {
  case indices, stack {
    [], [] | [], _stack -> k

    [first, ..rest_indices], [] -> detect_adjacent(rest_indices, k, [first])

    [curr, ..rest_indices], [prev, ..rest_stack] -> {
      let #(second_start, second_end) = curr
      let #(first_start, first_end) = prev
      let first_length = first_end - first_start
      let second_length = second_end - second_start

      case second_length == first_length {
        True -> detect_adjacent(rest_indices, second_length, rest_stack)
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
    [], [] | [], _mono_stack -> detect_adjacent(indices, 0, [])

    [curr, ..rest], mono_stack -> {
      let prev = mono_stack |> list.first |> result.unwrap(-1)

      case curr - prev == 1, curr_count == 0 {
        True, True | True, False -> {
          detect_increasing_subarrays(rest, curr_count + 1, index + 1, indices, [
            curr,
            ..mono_stack
          ])
        }
        False, True -> {
          detect_increasing_subarrays(rest, 0, index + 1, indices, [
            curr,
            ..mono_stack
          ])
        }
        False, False -> {
          detect_increasing_subarrays(
            rest,
            0,
            index + 1,
            [#(index - curr_count, index), ..indices],
            [curr],
          )
        }
      }
    }
  }
}

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
