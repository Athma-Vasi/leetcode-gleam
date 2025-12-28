import gleam/list
import gleam/result

// Find the index of the first negative number in a row
// Returns the index position where negative numbers start
fn find_index_of_first_negative(index: Int, found: Bool, row: List(Int)) {
  case row, found {
    // Base cases: empty row or already found negative number
    [], True | [], False | _row, True -> index

    // Recursive case: check if current number is negative
    [num, ..rest_row], False ->
      find_index_of_first_negative(
        case num < 0 {
          True -> index
          False -> index + 1
        },
        num < 0,
        rest_row,
      )
  }
}

// Count all negative numbers in a sorted matrix
// The matrix is sorted in descending order by rows and columns
// Time Complexity: O(m * n) - processes each row to find first negative
// Space Complexity: O(1) - only uses constant extra space
fn count_negative_numbers(grid: List(List(Int))) {
  // Get the number of columns from the first row
  let columns_count = list.first(grid) |> result.unwrap(or: []) |> list.length
  let initial_count = 0

  // Fold through each row, counting negative numbers
  grid
  |> list.fold(from: initial_count, with: fn(count, row) {
    // Find where negative numbers start in this row
    let index_of_first_negative = find_index_of_first_negative(0, False, row)
    // All numbers from first negative index to end are negative
    let negatives_in_row = columns_count - index_of_first_negative
    count + negatives_in_row
  })
}

pub fn run() {
  // Test case 1: matrix with mixed positive and negative numbers
  let g1 = [[4, 3, 2, -1], [3, 2, 1, -1], [1, 1, -1, -2], [-1, -1, -2, -3]]
  // Expected output: 8
  echo count_negative_numbers(g1)

  // Test case 2: matrix with no negative numbers
  let g2 = [[3, 2], [1, 0]]
  // Expected output: 0
  echo count_negative_numbers(g2)
}
