import gleam/list

/// Detects if the given 3-element window contains a duplicate value.
/// 
/// Strategy: In a sliding window of size 3, since the array of size 2n contains
/// n+1 distinct values with one repeated, any 3-element window can detect the
/// repeated value if it appears at least twice within those 3 positions.
/// 
/// This checks three cases:
/// 1. Adjacent duplicates: first == second or second == third
/// 2. Non-adjacent duplicates in window: first == third
/// 3. No duplicates in this window: returns the accumulated result (default)
fn find_duplicate(first: Int, second: Int, third: Int, default: Int) {
  case first == second, second == third {
    True, True | True, False -> first
    False, True -> second
    False, False ->
      case first == third {
        True -> first
        False -> default
      }
  }
}

/// Slides a 3-element window across the array, checking each window for duplicates.
/// 
/// Algorithm Overview:
/// - Maintains a queue (window) of the last 3 elements seen
/// - For each new element, checks if the current 3-element window contains duplicates
/// - Shifts the window forward: removes first, keeps second and third, adds new element
/// - Propagates the detected duplicate (or -1 if none found) through recursion
/// 
/// Time Complexity: O(n) - single pass through the list
/// Space Complexity: O(1) - only stores 3 elements and uses tail recursion
fn slide_window(repeated: Int, queue: #(Int, Int, Int), nums: List(Int)) {
  let #(first, second, third) = queue

  case nums {
    [] -> find_duplicate(first, second, third, repeated)

    [num, ..rest_nums] ->
      case first, second, third {
        -1, -1, -1 -> slide_window(repeated, #(num, -1, -1), rest_nums)

        first, -1, -1 -> slide_window(repeated, #(first, num, -1), rest_nums)

        first, second, -1 ->
          slide_window(repeated, #(first, second, num), rest_nums)

        first, second, third ->
          find_duplicate(first, second, third, repeated)
          |> slide_window(#(second, third, num), rest_nums)
      }
  }
}

/// Finds the single repeated element in an array of size 2n containing n+1 distinct values.
/// 
/// Problem Constraint: Given an array of size 2n with values in range [1, n],
/// exactly one value appears twice, and we need to find it.
/// 
/// Edge Case Optimization: If the first and last elements are equal, we can immediately
/// return that value without scanning the entire array, as a subarray of size 3 cannot
/// detect case where nums = [x, 1, 2, x]
fn find_repeated_element(nums: List(Int)) {
  case nums |> list.first, nums |> list.last {
    Ok(first), Ok(last) -> {
      case first == last {
        True -> first
        False -> slide_window(-1, #(-1, -1, -1), nums)
      }
    }

    Error(Nil), Error(Nil) | Ok(_first), Error(Nil) | Error(Nil), Ok(_second) ->
      -1
  }
}

/// Test cases for the duplicate finding algorithm.
/// Expected outputs demonstrate the algorithm's ability to find repeated elements
/// regardless of their position or frequency within the array.
pub fn run() {
  // Test 1: Adjacent duplicates at the end
  let n1 = [1, 2, 3, 3]
  echo find_repeated_element(n1)
  // Expected: 3

  // Test 2: Repeated element scattered throughout the array
  let n2 = [2, 1, 2, 5, 3, 2]
  echo find_repeated_element(n2)
  // Expected: 2

  // Test 3: Repeated element appears multiple times, spread out
  let n3 = [5, 1, 5, 2, 5, 3, 5, 4]
  echo find_repeated_element(n3)
  // Expected: 5

  // Test 4: First and last elements match (edge case optimization)
  let n4 = [1, 2, 3, 1]
  echo find_repeated_element(n4)
  // Expected: 1
}
