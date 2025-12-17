import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/set

type Boxes {
  Box1
  Box2
  Box3
  Box4
  Box5
  Box6
  Box7
  Box8
  Box9
}

type RowsTable =
  dict.Dict(Int, set.Set(Int))

type ColsTable =
  RowsTable

type BoxesTable =
  dict.Dict(Boxes, set.Set(Int))

// Map a cell at (row_index, col_index) to its 3x3 box.
// A Sudoku board is divided into 9 boxes, each 3×3.
// Box assignment: floor(row / 3) × 3 + floor(col / 3)
fn return_box(row_index: Int, col_index: Int) -> Boxes {
  let box_row = int.floor_divide(row_index, 3) |> result.unwrap(or: 0)
  let box_col = int.floor_divide(col_index, 3) |> result.unwrap(or: 0)

  case box_row, box_col {
    0, 0 -> Box1
    0, 1 -> Box2
    0, 2 -> Box3
    1, 0 -> Box4
    1, 1 -> Box5
    1, 2 -> Box6
    2, 0 -> Box7
    2, 1 -> Box8
    2, 2 -> Box9
    _, _ -> Box9
  }
  // case row_index, col_index {
  //   0, 0 | 0, 1 | 0, 2 | 1, 0 | 1, 1 | 1, 2 | 2, 0 | 2, 1 | 2, 2 -> Box1
  //   0, 3 | 0, 4 | 0, 5 | 1, 3 | 1, 4 | 1, 5 | 2, 3 | 2, 4 | 2, 5 -> Box2
  //   0, 6 | 0, 7 | 0, _ | 1, 6 | 1, 7 | 1, _ | 2, 6 | 2, 7 | 2, _ -> Box3
  //   3, 0 | 3, 1 | 3, 2 | 4, 0 | 4, 1 | 4, 2 | 5, 0 | 5, 1 | 5, 2 -> Box4
  //   3, 3 | 3, 4 | 3, 5 | 4, 3 | 4, 4 | 4, 5 | 5, 3 | 5, 4 | 5, 5 -> Box5
  //   3, 6 | 3, 7 | 3, _ | 4, 6 | 4, 7 | 4, _ | 5, 6 | 5, 7 | 5, _ -> Box6
  //   6, 0 | 6, 1 | 6, 2 | 7, 0 | 7, 1 | 7, 2 | _, 0 | _, 1 | _, 2 -> Box7
  //   6, 3 | 6, 4 | 6, 5 | 7, 3 | 7, 4 | 7, 5 | _, 3 | _, 4 | _, 5 -> Box8
  //   6, 6 | 6, 7 | 6, _ | 7, 6 | 7, 7 | 7, _ | _, 6 | _, 7 | _, _ -> Box9
  // }
}

// T(n) = O(1) - exactly 81 cells processed
// S(n) = O(1) - at most 9 rows × 9 cols × 9 boxes, each storing ≤9 digits
fn check_validity(board: List(List(String))) -> Bool {
  let initial_rows_table: RowsTable = dict.new()
  let initial_cols_table: ColsTable = dict.new()
  let initial_boxes_table: BoxesTable = dict.new()
  let initial_validity = True
  let initial_acc = #(
    initial_validity,
    initial_rows_table,
    initial_cols_table,
    initial_boxes_table,
  )

  let #(is_valid, _rows_table, _cols_table, _boxes_table) =
    board
    |> list.index_fold(from: initial_acc, with: fn(acc, row, row_index) {
      row
      |> list.index_fold(from: acc, with: fn(acc, cell_str, col_index) {
        let #(is_valid, rows_table, cols_table, boxes_table) = acc

        case is_valid, int.parse(cell_str) {
          // Early exit: if we already found a duplicate, keep returning False
          False, Error(Nil) | False, Ok(_cell_num) -> #(
            False,
            rows_table,
            cols_table,
            boxes_table,
          )

          // Skip empty cells (".") and continue validating
          True, Error(Nil) -> #(is_valid, rows_table, cols_table, boxes_table)

          // Cell has a digit: check for duplicates in row, column, and box
          True, Ok(cell_num) -> {
            let row_set =
              rows_table
              |> dict.get(row_index)
              |> result.unwrap(or: set.new())
            let col_set =
              cols_table
              |> dict.get(col_index)
              |> result.unwrap(or: set.new())
            let box = return_box(row_index, col_index)
            let box_set =
              boxes_table
              |> dict.get(box)
              |> result.unwrap(or: set.new())

            // Check if cell_num already appears in row, column, or box
            case
              row_set |> set.contains(cell_num),
              col_set |> set.contains(cell_num),
              box_set |> set.contains(cell_num)
            {
              // Duplicate found: mark invalid and stop updating tables
              True, _, _ | _, True, _ | _, _, True -> #(
                False,
                rows_table,
                cols_table,
                boxes_table,
              )

              // No duplicate: record this number in row, column, and box
              False, False, False -> #(
                is_valid,
                rows_table
                  |> dict.insert(row_index, row_set |> set.insert(cell_num)),
                cols_table
                  |> dict.insert(col_index, col_set |> set.insert(cell_num)),
                boxes_table
                  |> dict.insert(box, box_set |> set.insert(cell_num)),
              )
            }
          }
        }
      })
    })

  is_valid
}

pub fn run() {
  let b1 = [
    ["5", "3", ".", ".", "7", ".", ".", ".", "."],
    ["6", ".", ".", "1", "9", "5", ".", ".", "."],
    [".", "9", "8", ".", ".", ".", ".", "6", "."],
    ["8", ".", ".", ".", "6", ".", ".", ".", "3"],
    ["4", ".", ".", "8", ".", "3", ".", ".", "1"],
    ["7", ".", ".", ".", "2", ".", ".", ".", "6"],
    [".", "6", ".", ".", ".", ".", "2", "8", "."],
    [".", ".", ".", "4", "1", "9", ".", ".", "5"],
    [".", ".", ".", ".", "8", ".", ".", "7", "9"],
  ]
  // True
  echo check_validity(b1)

  let b2 = [
    ["8", "3", ".", ".", "7", ".", ".", ".", "."],
    ["6", ".", ".", "1", "9", "5", ".", ".", "."],
    [".", "9", "8", ".", ".", ".", ".", "6", "."],
    ["8", ".", ".", ".", "6", ".", ".", ".", "3"],
    ["4", ".", ".", "8", ".", "3", ".", ".", "1"],
    ["7", ".", ".", ".", "2", ".", ".", ".", "6"],
    [".", "6", ".", ".", ".", ".", "2", "8", "."],
    [".", ".", ".", "4", "1", "9", ".", ".", "5"],
    [".", ".", ".", ".", "8", ".", ".", "7", "9"],
  ]
  // False
  echo check_validity(b2)
}
