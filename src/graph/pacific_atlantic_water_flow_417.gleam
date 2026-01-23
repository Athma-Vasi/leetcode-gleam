// LeetCode 417: Pacific Atlantic Water Flow
// Given an m x n matrix of non-negative integers representing the height of each cell,
// find all cells where water can flow to both the Pacific and Atlantic oceans.
// Water can flow from a cell to another one with height equal or lower (in 4 directions).
// The Pacific touches the left and top edges, the Atlantic touches the right and bottom edges.

import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set

// Represents the content of a cell in the grid
// Pacific: virtual cell representing the Pacific Ocean (top/left border)
// Atlantic: virtual cell representing the Atlantic Ocean (bottom/right border)
// Land: actual grid cell with an integer height value
pub type CellContent {
  Pacific
  Atlantic
  Land(value: Int)
}

// Grid representation: 2D list of CellContent (land heights + ocean borders)
type Grid =
  List(List(CellContent))

// Cell coordinate as (row, column) tuple
type CellCoordinate =
  #(Int, Int)

// Result types for directional paths from a cell to its neighbor
// Ok contains the neighbor's coordinate and content
// Error(Nil) means no valid path exists in that direction
type TopPathResult =
  Result(#(CellCoordinate, CellContent), Nil)

type RightPathResult =
  TopPathResult

type DownPathResult =
  RightPathResult

type LeftPathResult =
  DownPathResult

type CellContentResult =
  Result(CellContent, Nil)

// Adjacency list representing the directed graph of water flow
// Each cell maps to a 5-tuple containing:
// 1. Cell's content (Land value or Ocean type)
// 2-5. Paths to top, right, down, and left neighbors (if water can flow there)
// Water flows from current cell to neighbor only if neighbor's height <= current height
type AdjacencyList =
  dict.Dict(
    CellCoordinate,
    #(
      CellContentResult,
      TopPathResult,
      RightPathResult,
      DownPathResult,
      LeftPathResult,
    ),
  )

// Temporary table to track cells from the previous row during graph construction
// Used to establish vertical (top-down) connections efficiently
type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

// Transforms the input grid by adding ocean borders
// Adds Pacific Ocean cells to top and left borders
// Adds Atlantic Ocean cells to bottom and right borders
// This creates a (m+2) x (n+2) grid where original grid is surrounded by oceans
// Time: O(m * n) where m = rows, n = columns
// Space: O(m * n) for the new grid with borders
fn add_oceans_to(grid: List(List(Int))) -> Grid {
  let number_of_rows = list.length(grid)
  let initial_with_oceans: Grid = []

  grid
  |> list.index_fold(
    from: initial_with_oceans,
    with: fn(grid_acc, row, row_index) {
      let number_of_columns = list.length(row)

      let initial_row_acc = []
      let row_with_oceans =
        row
        |> list.index_fold(
          from: initial_row_acc,
          with: fn(row_acc, cell, column_index) {
            case column_index == 0, column_index == number_of_columns - 1 {
              // First column: prepend Pacific ocean to the left
              True, False -> [Pacific, ..row_acc] |> list.append([Land(cell)])

              // Last column: append Atlantic ocean to the right
              False, True -> row_acc |> list.append([Land(cell), Atlantic])

              // Middle columns: just append the land cell
              False, False -> row_acc |> list.append([Land(cell)])

              // Single column grid: needs both Pacific (left) and Atlantic (right)
              True, True ->
                [Pacific, ..row_acc] |> list.append([Land(cell), Atlantic])
            }
          },
        )

      // Add Pacific row at top and Atlantic row at bottom
      case row_index == 0, row_index == number_of_rows - 1 {
        // First row: prepend a full row of Pacific ocean cells
        True, False -> {
          let pacific_row = Pacific |> list.repeat(times: number_of_columns + 2)

          [pacific_row, ..grid_acc]
          |> list.append([row_with_oceans])
        }

        // Last row: append a full row of Atlantic ocean cells
        False, True -> {
          let atlantic_row =
            Atlantic |> list.repeat(times: number_of_columns + 2)

          grid_acc
          |> list.append([row_with_oceans, atlantic_row])
        }

        // Middle rows: just append the row with ocean borders
        False, False -> grid_acc |> list.append([row_with_oceans])

        // Single row grid: needs both Pacific row (top) and Atlantic row (bottom)
        True, True -> {
          let pacific_row = Pacific |> list.repeat(times: number_of_columns + 2)
          let atlantic_row =
            Atlantic |> list.repeat(times: number_of_columns + 2)

          [pacific_row, ..grid_acc]
          |> list.append([row_with_oceans, atlantic_row])
        }
      }
    },
  )
}

// Updates the graph to record a valid downward water flow path from current cell to top cell
// Creates or updates the current cell's entry in the graph, setting the top path result
// Time: O(1) - dict upsert operation
// Space: O(1) - modifies existing dict
fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  top_cell_coordinate,
  top_cell_content,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(
        Ok(curr_cell_content),
        Ok(#(top_cell_coordinate, top_cell_content)),
        Error(Nil),
        Error(Nil),
        Error(Nil),
      )

      Some(path_results) -> {
        let #(
          _cell_content_result,
          _top_path_result,
          right_path_result,
          down_path_result,
          left_path_result,
        ) = path_results

        #(
          Ok(curr_cell_content),
          Ok(#(top_cell_coordinate, top_cell_content)),
          right_path_result,
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

// Updates the graph to record a valid rightward water flow path from current cell to left cell
// Creates or updates the current cell's entry, setting the left path result
// Time: O(1) - dict upsert operation
// Space: O(1) - modifies existing dict
fn update_current_cells_left_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  left_cell_coordinate,
  left_cell_content,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(
        Ok(curr_cell_content),
        Error(Nil),
        Error(Nil),
        Error(Nil),
        Ok(#(left_cell_coordinate, left_cell_content)),
      )

      Some(path_results) -> {
        let #(
          _cell_content_result,
          top_path_result,
          right_path_result,
          down_path_result,
          _left_path_result,
        ) = path_results

        #(
          Ok(curr_cell_content),
          top_path_result,
          right_path_result,
          down_path_result,
          Ok(#(left_cell_coordinate, left_cell_content)),
        )
      }
    }
  })
}

// Updates the graph to record a valid leftward water flow path from left cell to current cell
// Creates or updates the left cell's entry, setting the right path result
// Time: O(1) - dict upsert operation
// Space: O(1) - modifies existing dict
fn update_left_cells_right_path(
  graph,
  left_cell_coordinate,
  left_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(
        Ok(left_cell_content),
        Error(Nil),
        Ok(#(curr_cell_coordinate, curr_cell_content)),
        Error(Nil),
        Error(Nil),
      )

      Some(path_results) -> {
        let #(
          _cell_content_result,
          top_path_result,
          _right_path_result,
          down_path_result,
          left_path_result,
        ) = path_results

        #(
          Ok(left_cell_content),
          top_path_result,
          Ok(#(curr_cell_coordinate, curr_cell_content)),
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

// Updates the graph to record a valid upward water flow path from top cell to current cell
// Creates or updates the top cell's entry, setting the down path result
// Time: O(1) - dict upsert operation
// Space: O(1) - modifies existing dict
fn update_top_cells_down_path(
  graph,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(
        Ok(top_cell_content),
        Error(Nil),
        Error(Nil),
        Ok(#(curr_cell_coordinate, curr_cell_content)),
        Error(Nil),
      )

      Some(path_results) -> {
        let #(
          _cell_content_result,
          top_path_result,
          right_path_result,
          _down_path_result,
          left_path_result,
        ) = path_results

        #(
          Ok(top_cell_content),
          top_path_result,
          right_path_result,
          Ok(#(curr_cell_coordinate, curr_cell_content)),
          left_path_result,
        )
      }
    }
  })
}

// Updates bidirectional flow paths for equal-height cells (plateau scenario)
// Establishes paths: left<->current and top<->current
// This creates cycles in the graph, allowing water to flow in both directions
// Time: O(1) - four dict upsert operations
// Space: O(1) - modifies existing dict
fn update_left_top_and_current_cells(
  graph,
  left_cell_coordinate,
  left_cell_content,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) {
  graph
  |> update_left_cells_right_path(
    left_cell_coordinate,
    left_cell_content,
    curr_cell_coordinate,
    curr_cell_content,
  )
  |> update_top_cells_down_path(
    top_cell_coordinate,
    top_cell_content,
    curr_cell_coordinate,
    curr_cell_content,
  )
  |> update_current_cells_left_path(
    curr_cell_coordinate,
    curr_cell_content,
    left_cell_coordinate,
    left_cell_content,
  )
  |> update_current_cells_top_path(
    curr_cell_coordinate,
    curr_cell_content,
    top_cell_coordinate,
    top_cell_content,
  )
}

// Updates bidirectional flow paths between left and current cells
// Used when left and current cells have equal height
// Time: O(1) - two dict upsert operations
// Space: O(1) - modifies existing dict
fn update_left_and_current_cells(
  graph,
  left_cell_coordinate,
  left_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) {
  graph
  |> update_left_cells_right_path(
    left_cell_coordinate,
    left_cell_content,
    curr_cell_coordinate,
    curr_cell_content,
  )
  |> update_current_cells_left_path(
    curr_cell_coordinate,
    curr_cell_content,
    left_cell_coordinate,
    left_cell_content,
  )
}

// Updates bidirectional flow paths between top and current cells
// Used when top and current cells have equal height
// Time: O(1) - two dict upsert operations
// Space: O(1) - modifies existing dict
fn update_top_and_current_cells(
  graph,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) {
  graph
  |> update_top_cells_down_path(
    top_cell_coordinate,
    top_cell_content,
    curr_cell_coordinate,
    curr_cell_content,
  )
  |> update_current_cells_top_path(
    curr_cell_coordinate,
    curr_cell_content,
    top_cell_coordinate,
    top_cell_content,
  )
}

// Updates the current cell's paths to both left and top neighbors
// Used when water can flow from current cell to both neighbors (their heights <= current)
// Time: O(1) - two dict upsert operations
// Space: O(1) - modifies existing dict
fn update_current_cells_left_and_top_paths(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  left_cell_coordinate,
  left_cell_content,
  top_cell_coordinate,
  top_cell_content,
) {
  graph
  |> update_current_cells_left_path(
    curr_cell_coordinate,
    curr_cell_content,
    left_cell_coordinate,
    left_cell_content,
  )
  |> update_current_cells_top_path(
    curr_cell_coordinate,
    curr_cell_content,
    top_cell_coordinate,
    top_cell_content,
  )
}

// Builds a directed graph representing valid water flow paths
// Processes grid left-to-right, top-to-bottom, establishing edges based on height comparisons
// An edge from A to B exists if water can flow from A to B (height_B <= height_A)
// For equal heights, creates bidirectional edges (plateau scenario)
// Time: O(m * n) where m = rows, n = columns (processes each cell once)
// Space: O(m * n) for the adjacency list storing up to 4 edges per cell
fn build_graph(grid: Grid) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()

  let #(_prev_row_table, graph) =
    grid
    |> list.index_fold(
      from: #(initial_prev_row_table, initial_graph),
      with: fn(row_acc, row, row_index) {
        let #(prev_row_table, graph) = row_acc

        let initial_left_cell_content = Pacific

        let #(_left_cell_content, updated_prev_row_table, updated_graph) =
          row
          |> list.index_fold(
            from: #(initial_left_cell_content, prev_row_table, graph),
            with: fn(column_acc, curr_cell_content, column_index) {
              let #(left_cell_content, prev_row_table, graph) = column_acc

              // Get the cell above (from previous row)
              // If no previous row exists, default to Pacific ocean
              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell_content =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: Pacific)

              let curr_cell_coordinate = #(row_index, column_index)
              // Update prev_row_table: add current cell, remove old top cell
              // This sliding window approach keeps memory usage O(n) instead of O(m*n)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(
                  for: curr_cell_coordinate,
                  insert: curr_cell_content,
                )
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)

              // Pattern match on (left, top, current) cell contents to determine flow edges
              // Water flows from higher/equal cells to lower/equal cells
              case left_cell_content, top_cell_content, curr_cell_content {
                // Top-left corner: Pacific ocean cell, no edges needed
                Pacific, Pacific, Pacific -> {
                  #(curr_cell_content, updated_prev_row_table, graph)
                }
                // Bottom-left corner: Atlantic ocean cell at bottom row, first column
                Atlantic, Pacific, Atlantic -> {
                  #(curr_cell_content, updated_prev_row_table, graph)
                }
                // Bottom row Atlantic cells (except corners): establish connection with cell above
                Atlantic, top_cell_content, Atlantic -> {
                  #(
                    curr_cell_content,
                    updated_prev_row_table,
                    graph
                      |> update_top_cells_down_path(
                        top_cell_coordinate,
                        top_cell_content,
                        curr_cell_coordinate,
                        curr_cell_content,
                      ),
                  )
                }

                // Right column Atlantic cells: establish connection with cell to the left
                // Covers both first row and last row Atlantic cells on the right edge
                left_cell_content, Pacific, Atlantic
                | left_cell_content, Atlantic, Atlantic
                -> {
                  #(
                    curr_cell_content,
                    updated_prev_row_table,
                    graph
                      |> update_left_cells_right_path(
                        left_cell_coordinate,
                        left_cell_content,
                        curr_cell_coordinate,
                        curr_cell_content,
                      ),
                  )
                }

                // Top-left land cell (1,1): water flows to both Pacific borders (left and top)
                Pacific, Pacific, curr_cell_content -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> update_current_cells_left_and_top_paths(
                      curr_cell_coordinate,
                      curr_cell_content,
                      left_cell_coordinate,
                      left_cell_content,
                      top_cell_coordinate,
                      top_cell_content,
                    ),
                )

                // First column land cells: compare heights to establish flow direction
                // Left is always Pacific, so only need to compare with top cell
                Pacific, Land(top_cell_value), Land(curr_cell_value) ->
                  case
                    top_cell_value < curr_cell_value,
                    top_cell_value == curr_cell_value
                  {
                    // Impossible case: value cannot be both less than and equal to current
                    True, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph,
                    )

                    True, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_and_top_paths(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )

                    False, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_top_and_current_cells(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                        ),
                    )

                    // Top cell higher: water flows up from top to current
                    False, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_top_cells_down_path(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                        ),
                    )
                  }

                // First row land cells: compare heights to establish flow direction
                // Top is always Pacific, so only need to compare with left cell
                Land(left_cell_value), Pacific, Land(curr_cell_value) -> {
                  case
                    left_cell_value < curr_cell_value,
                    left_cell_value == curr_cell_value
                  {
                    // Impossible case: value cannot be both less than and equal to current
                    True, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph,
                    )

                    True, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_and_top_paths(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )

                    False, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_and_current_cells(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )

                    // Left cell higher: water flows right from left to current
                    False, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_cells_right_path(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )
                  }
                }

                // Interior land cells: compare with both left and top neighbors
                // Need to handle all combinations of height relationships (9 cases)
                Land(left_cell_value),
                  Land(top_cell_value),
                  Land(curr_cell_value)
                -> {
                  case
                    left_cell_value < curr_cell_value,
                    left_cell_value == curr_cell_value,
                    top_cell_value < curr_cell_value,
                    top_cell_value == curr_cell_value
                  {
                    // Impossible cases where cell is simultaneously less than and equal to current
                    True, True, True, False
                    | True, True, False, False
                    | True, True, False, True
                    -> #(curr_cell_content, updated_prev_row_table, graph)

                    // top cell cannot both be less and equal
                    False, False, True, True
                    | True, False, True, True
                    | False, True, True, True
                    -> #(curr_cell_content, updated_prev_row_table, graph)

                    // left and top cells cannot both be less and equal
                    True, True, True, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph,
                    )

                    // Both neighbors lower: water flows outward to both left and top
                    True, False, True, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_and_top_paths(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )

                    // Both neighbors equal: bidirectional flow to both (plateau)
                    False, True, False, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_top_and_current_cells(
                          left_cell_coordinate,
                          left_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        ),
                    )

                    // Left lower, top equal: flow left (unidirectional) and top (bidirectional)
                    True, False, False, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                        )
                        |> update_top_and_current_cells(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        ),
                    )

                    // Left equal, top lower: flow top (unidirectional) and left (bidirectional)
                    False, True, True, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_and_current_cells(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )

                    // Left higher, top lower: flow from left (inward) and to top (outward)
                    False, False, True, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_cells_right_path(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                          top_cell_content,
                        ),
                    )

                    // Left higher, top equal: flow from left (inward) and top (bidirectional)
                    False, False, False, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_cells_right_path(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_top_and_current_cells(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        ),
                    )

                    // Left lower, top higher: flow to left (outward) and from top (inward)
                    True, False, False, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                          left_cell_content,
                        )
                        |> update_top_cells_down_path(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        ),
                    )

                    // Left equal, top higher: flow left (bidirectional) and from top (inward)
                    False, True, False, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_and_current_cells(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_top_cells_down_path(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        ),
                    )

                    // Both neighbors higher: water flows inward from both left and top
                    False, False, False, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_cells_right_path(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        )
                        |> update_top_cells_down_path(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                          curr_cell_content,
                        ),
                    )
                  }
                }

                // Impossible states that violate grid structure constraints
                // (These patterns cannot occur given how we add oceans)
                Pacific, Land(_), Pacific
                | Pacific, Land(_), Atlantic
                | Pacific, Atlantic, _
                | Land(_), Pacific, Pacific
                | Land(_), Land(_), Pacific
                | Land(_), Land(_), Atlantic
                | Land(_), Atlantic, Pacific
                | Land(_), Atlantic, Land(_)
                | Atlantic, Pacific, Land(_)
                | Atlantic, Pacific, Pacific
                | Atlantic, Land(_), Pacific
                | Atlantic, Land(_), Land(_)
                | Atlantic, Atlantic, Pacific
                | Atlantic, Atlantic, Land(_)
                -> {
                  #(curr_cell_content, updated_prev_row_table, graph)
                }
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

// Performs DFS to determine if both oceans are reachable from a starting cell
// Uses an explicit stack instead of recursion to avoid stack overflow on large grids
// Tracks visited cells to prevent infinite loops in graph cycles (plateaus)
// Time: O(m * n) worst case - visits each cell at most once per DFS
// Space: O(m * n) for visited set and stack in worst case
fn calculate_if_oceans_are_reachable(
  graph: AdjacencyList,
  itinerary_stack: List(#(CellCoordinate, CellContent)),
  visited: set.Set(CellCoordinate),
  is_connected_to_pacific: Bool,
  is_connected_to_atlantic: Bool,
) {
  case itinerary_stack, is_connected_to_pacific, is_connected_to_atlantic {
    // Success: reached both oceans (can short-circuit even if stack has items)
    [], True, True | [_first, ..], True, True -> True

    // Failure: exhausted all paths without reaching both oceans
    [], False, True | [], True, False | [], False, False -> False

    // Continue DFS: still have cells to explore, haven't reached both oceans yet
    [first, ..rest_stack], True, False
    | [first, ..rest_stack], False, True
    | [first, ..rest_stack], False, False
    -> {
      let #(curr_cell_coordinate, curr_cell_content) = first
      let already_visited = visited |> set.contains(curr_cell_coordinate)

      case already_visited, curr_cell_content {
        // Already visited Pacific: skip to avoid redundant work
        True, Pacific ->
          calculate_if_oceans_are_reachable(
            graph,
            rest_stack,
            visited,
            is_connected_to_pacific,
            is_connected_to_atlantic,
          )
        // First time reaching Pacific: mark as connected and continue
        False, Pacific ->
          calculate_if_oceans_are_reachable(
            graph,
            rest_stack,
            visited |> set.insert(curr_cell_coordinate),
            True,
            is_connected_to_atlantic,
          )

        // Already visited Atlantic: skip to avoid redundant work
        True, Atlantic ->
          calculate_if_oceans_are_reachable(
            graph,
            rest_stack,
            visited,
            is_connected_to_pacific,
            is_connected_to_atlantic,
          )
        // First time reaching Atlantic: mark as connected and continue
        False, Atlantic ->
          calculate_if_oceans_are_reachable(
            graph,
            rest_stack,
            visited |> set.insert(curr_cell_coordinate),
            is_connected_to_pacific,
            True,
          )

        // Already visited this land cell: skip to prevent infinite loops
        True, Land(_) ->
          calculate_if_oceans_are_reachable(
            graph,
            rest_stack,
            visited,
            is_connected_to_pacific,
            is_connected_to_atlantic,
          )

        // Unvisited land cell: explore all outgoing edges (water flow paths)
        False, Land(_curr_cell_value) -> {
          let updated_set = visited |> set.insert(curr_cell_coordinate)

          case graph |> dict.get(curr_cell_coordinate) {
            // Cell not in graph (isolated): continue with remaining stack
            Error(Nil) ->
              calculate_if_oceans_are_reachable(
                graph,
                rest_stack,
                updated_set,
                is_connected_to_pacific,
                is_connected_to_atlantic,
              )

            // Cell has edges: add all valid neighbors to stack for DFS exploration
            // Each case below handles different combinations of available paths
            Ok(path_results) -> {
              let #(
                _cell_content_result,
                top_path_result,
                right_path_result,
                down_path_result,
                left_path_result,
              ) = path_results
              case
                top_path_result,
                right_path_result,
                down_path_result,
                left_path_result
              {
                // No valid neighbors: continue with remaining stack
                Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    rest_stack,
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [down_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [right_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [down_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [right_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [right_path, down_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [right_path, down_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, down_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, down_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, right_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, right_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, right_path, down_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )

                Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
                  calculate_if_oceans_are_reachable(
                    graph,
                    [top_path, right_path, down_path, left_path, ..rest_stack],
                    updated_set,
                    is_connected_to_pacific,
                    is_connected_to_atlantic,
                  )
              }
            }
          }
        }
      }
    }
  }
}

// Identifies all cells that can flow to both Pacific and Atlantic oceans
// Iterates through each land cell and performs DFS to check ocean reachability
// Returns coordinates adjusted back to original grid (subtracting ocean border offsets)
// Time: O(m * n * (m * n)) worst case - DFS for each cell
//       In practice much faster due to early termination and shared paths
// Space: O(m * n) for result set and per-DFS visited set
fn determine_flow(graph: AdjacencyList, grid: Grid) {
  grid
  |> list.index_fold(from: set.new(), with: fn(acc, row, row_index) {
    row
    |> list.index_fold(from: acc, with: fn(row_acc, cell, column_index) {
      case cell {
        // Skip ocean cells - we only check land cells
        Pacific | Atlantic -> row_acc

        curr_cell_content -> {
          let cell_coordinate = #(row_index, column_index)
          // Perform DFS to check if this cell can reach both oceans
          let is_curr_cell_connected_to_both_oceans =
            calculate_if_oceans_are_reachable(
              graph,
              [#(cell_coordinate, curr_cell_content)],
              set.new(),
              False,
              False,
            )

          case is_curr_cell_connected_to_both_oceans {
            // Success: add to result set with adjusted coordinates (remove ocean borders)
            True -> row_acc |> set.insert(#(row_index - 1, column_index - 1))

            // Failure: cell doesn't reach both oceans, skip it
            False -> row_acc
          }
        }
      }
    })
  })
  |> set.to_list
}

// Main solution function: orchestrates the entire algorithm
// 1. Add ocean borders to grid
// 2. Build directed graph of water flow paths
// 3. Find all cells that can reach both oceans
// Overall Time Complexity: O(m * n * (m * n)) worst case
//   - O(m * n) to add oceans
//   - O(m * n) to build graph
//   - O(m * n * (m * n)) to check each cell with DFS
// Overall Space Complexity: O(m * n) for graph and intermediate structures
fn t(grid: List(List(Int))) {
  let with_oceans_added = add_oceans_to(grid)
  build_graph(with_oceans_added) |> determine_flow(with_oceans_added)
}

// ============================================================================
// Test Cases
// ============================================================================
// Comprehensive test suite covering various grid configurations and edge cases

pub fn run() {
  // Test case 1: 5x5 grid with mixed heights
  let grid1 = [
    [1, 2, 2, 3, 5],
    [3, 2, 3, 4, 4],
    [2, 4, 5, 3, 1],
    [6, 7, 1, 4, 5],
    [5, 1, 1, 2, 4],
  ]
  io.println("Test 1 (5x5 mixed):")
  io.println(
    "Expected: [#(0,4), #(1,3), #(1,4), #(2,2), #(3,0), #(3,1), #(4,0)]",
  )
  echo t(grid1)

  // Test case 2: Single cell
  let grid2 = [[5]]
  io.println("\nTest 2 (1x1):")
  io.println("Expected: [#(0,0)] - touches both Pacific and Atlantic edges")
  echo t(grid2)

  // Test case 3: 2x2 grid
  let grid3 = [[1, 2], [2, 1]]
  io.println("\nTest 3 (2x2):")
  io.println(
    "Expected: [#(0,1), #(1,0)] - flow between top-right and bottom-left",
  )
  echo t(grid3)

  // Test case 4: Increasing spiral - corners only
  let grid4 = [[1, 2, 3], [8, 9, 4], [7, 6, 5]]
  io.println("\nTest 4 (spiral increasing):")
  io.println(
    "Expected: [#(0, 2), #(1, 0), #(1, 1), #(1, 2), #(2, 0), #(2, 1), #(2, 2)] - top-right (Atlantic), bottom-left (Pacific)",
  )
  echo t(grid4)
}
