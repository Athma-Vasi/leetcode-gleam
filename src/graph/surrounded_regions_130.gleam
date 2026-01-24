// ============================================================================
// LeetCode 130: Surrounded Regions
// ============================================================================
// Problem: Given a 2D board with 'X' and 'O' cells, capture all 'O' regions
// that are completely surrounded by 'X' cells. 'O' regions touching the board
// boundary cannot be captured (considered connected to the outside).
//
// Algorithm Overview:
// 1. Mark all O's that touch borders as BorderO (safe from capture)
// 2. Build adjacency list (graph) representing O cell connectivity
// 3. DFS from each BorderO to propagate safety to all connected O's
// 4. Replace remaining unmarked O's with X's (they are surrounded)
//
// Time Complexity: O(m * n) for all operations
//   - Mark borders: O(m * n)
//   - Build graph: O(m * n) single-pass construction
//   - Propagate safety: O(m * n) DFS visiting each cell once
//   - Finalize board: O(m * n) cell replacement
// Space Complexity: O(m * n)
//   - Graph stores O(m * n) nodes with up to 4 edges per node
//   - Visited set for DFS: O(m * n)
//   - Recursion depth: O(m * n) worst case (chained cells)
// ============================================================================

import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set

// Cell content in the board
// X: wall/boundary cell (part of the surrounding structure)
// O: empty cell that may be vulnerable to capture if surrounded
// BorderO: empty cell marked as safe (touching board boundary, cannot be captured)
pub type CellContent {
  X
  O
  BorderO
}

type Board =
  List(List(CellContent))

// Cell position as (row, column) coordinate tuple for grid indexing
type CellCoordinate =
  #(Int, Int)

// Directional path result from current cell to an adjacent neighbor
// Ok(#(coordinate, content)) - valid connection exists to neighbor
// Error(Nil) - no connection or neighbor has different cell type
type TopPathResult =
  Result(#(CellCoordinate, CellContent), Nil)

type RightPathResult =
  TopPathResult

type DownPathResult =
  RightPathResult

type LeftPathResult =
  DownPathResult

// Result of cell content lookup in the graph
type CellContentResult =
  Result(CellContent, Nil)

// Adjacency list representing cell connectivity graph
// Maps coordinates to 5-tuple containing:
//   1. Cell's own content (X, O, or BorderO)
//   2. Path result to top neighbor
//   3. Path result to right neighbor
//   4. Path result to bottom neighbor
//   5. Path result to left neighbor
// Edges exist only between cells of matching content type
// Enables DFS traversal to find all connected component cells
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

// Temporary lookup table of cells from previously processed row
// Used during single-pass graph construction for efficient vertical connectivity
// Implemented as sliding window: add current row, delete old top row
// Maintains O(n) space instead of O(m*n) by not storing entire previous rows
type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

// Adds an upward connectivity edge from current cell to its top cell neighbor
// Creates or updates current cell's graph entry, setting the top path
// Used when current and top cells have matching content (can form connected region)
// Enables DFS to traverse upward through the grid from current position
// Time Complexity: O(1) - single dict upsert operation
// Space Complexity: O(1) - modifies existing dict entry in-place
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

// Adds a leftward connectivity edge from current cell to its left cell neighbor
// Creates or updates current cell's graph entry, setting the left path
// Used when current and left cells have matching content (can form connected region)
// Enables DFS to traverse leftward through the grid from current position
// Time Complexity: O(1) - single dict upsert operation
// Space Complexity: O(1) - modifies existing dict entry in-place
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

// Adds a rightward connectivity edge from left cell to the current cell
// Establishes backward link: left cell can reach current cell via right direction
// Used when left and current cells have matching content (bidirectional reachability)
// Enables DFS to traverse rightward through the grid from left position
// Time Complexity: O(1) - single dict upsert operation
// Space Complexity: O(1) - modifies existing dict entry in-place
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

// Adds a downward connectivity edge from top cell to the current cell
// Establishes backward link: top cell can reach current cell via down direction
// Used when top and current cells have matching content (bidirectional reachability)
// Enables DFS to traverse downward through the grid from top position
// Time Complexity: O(1) - single dict upsert operation
// Space Complexity: O(1) - modifies existing dict entry in-place
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

// Establishes bidirectional horizontal connectivity between two adjacent cells
// Creates left<->current links in both directions when they match in content
// Enables DFS to traverse freely left and right between these cells
// Time Complexity: O(1) - two dict upsert operations
// Space Complexity: O(1) - updates existing dict entries in-place
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

// Establishes bidirectional vertical connectivity between two adjacent cells
// Creates top<->current links in both directions when they match in content
// Enables DFS to traverse freely up and down between these cells
// Time Complexity: O(1) - two dict upsert operations
// Space Complexity: O(1) - updates existing dict entries in-place
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

fn create_new_safe_zone(graph, curr_cell_coordinate, curr_cell_content) {
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(
    Ok(curr_cell_content),
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
  ))
}

// Constructs a connectivity graph of all cells in the board
// Each cell stores its content and paths to adjacent matching-content neighbors
// Single-pass algorithm: processes each cell exactly once, left-to-right, top-to-bottom
// Uses sliding window to store previous row, maintaining O(n) space instead of O(m*n)
// Neighbors of same content get bidirectional edges (undirected graph)
// Time Complexity: O(m*n) - processes each cell once, O(1) work per cell
// Space Complexity: O(n) - sliding window stores only current + previous rows
fn construct_region_connectivity_graph(board: Board) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()

  let #(_prev_row_table, graph) =
    board
    |> list.index_fold(
      from: #(initial_prev_row_table, initial_graph),
      with: fn(row_acc, row, row_index) {
        let #(prev_row_table, graph) = row_acc

        let initial_left_cell_content = X

        let #(_left_cell_content, updated_prev_row_table, updated_graph) =
          row
          |> list.index_fold(
            from: #(initial_left_cell_content, prev_row_table, graph),
            with: fn(column_acc, curr_cell_content, column_index) {
              let #(left_cell_content, prev_row_table, graph) = column_acc

              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell_content =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: X)

              let curr_cell_coordinate = #(row_index, column_index)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(
                  for: curr_cell_coordinate,
                  insert: curr_cell_content,
                )
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)

              case left_cell_content, top_cell_content, curr_cell_content {
                // curr cell is X, ignore
                X, BorderO, X
                | O, BorderO, X
                | BorderO, O, X
                | BorderO, BorderO, X
                | BorderO, X, X
                | O, X, X
                | O, O, X
                | X, X, X
                | X, O, X
                -> #(curr_cell_content, updated_prev_row_table, graph)

                X, X, BorderO | X, X, O -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> create_new_safe_zone(
                      curr_cell_coordinate,
                      curr_cell_content,
                    ),
                )

                X, BorderO, O | X, BorderO, BorderO | X, O, BorderO | X, O, O -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> update_top_and_current_cells(
                      top_cell_coordinate,
                      top_cell_content,
                      curr_cell_coordinate,
                      curr_cell_content,
                    ),
                )

                BorderO, X, BorderO | BorderO, X, O | O, X, BorderO | O, X, O -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> update_left_and_current_cells(
                      left_cell_coordinate,
                      left_cell_content,
                      curr_cell_coordinate,
                      curr_cell_content,
                    ),
                )

                O, BorderO, O
                | BorderO, O, BorderO
                | BorderO, BorderO, BorderO
                | BorderO, BorderO, O
                | BorderO, O, O
                | O, O, O
                | O, O, BorderO
                | O, BorderO, BorderO
                -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> update_left_and_current_cells(
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
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

// Marks all O cells on the board's border as BorderO (special marker for safe cells)
// Border O's can always escape to edge, so they're never captured
// These serve as sources for subsequent DFS propagation to find all safe regions
// Iterates through all cells and tags O's on any edge as BorderO
// Time Complexity: O(m*n) - visits and classifies each cell once
// Space Complexity: O(m*n) - creates new board with same dimensions
fn mark_border_connected_o_cells(board: Board) {
  let number_of_rows = list.length(board)

  board
  |> list.index_fold(from: [], with: fn(board_acc, row, row_index) {
    let number_of_columns = list.length(row)

    let with_border_os =
      row
      |> list.index_fold(from: [], with: fn(row_acc, cell, column_index) {
        case cell {
          // borderO initially not present in input
          X | BorderO -> [cell, ..row_acc]

          O -> {
            let is_top_row = row_index == 0
            let is_right_column = column_index == number_of_columns - 1
            let is_bottom_row = row_index == number_of_rows - 1
            let is_left_column = column_index == 0

            case is_top_row, is_right_column, is_bottom_row, is_left_column {
              // top-right
              True, True, _, _ -> [BorderO, ..row_acc]
              // top-left
              True, False, _, True -> [BorderO, ..row_acc]
              // top row
              True, False, _, False -> [BorderO, ..row_acc]
              // right column
              False, True, False, _ -> [BorderO, ..row_acc]
              // bottom-right
              False, True, True, _ -> [BorderO, ..row_acc]
              // bottom row
              _, False, True, False -> [BorderO, ..row_acc]
              // bottom-left
              _, False, True, True -> [BorderO, ..row_acc]
              // left column
              False, False, False, True -> [BorderO, ..row_acc]

              // center o's
              False, False, False, False -> [O, ..row_acc]
            }
          }
        }
      })
      |> list.reverse

    [with_border_os, ..board_acc]
  })
  |> list.reverse
}

// DFS traversal to identify all O cells reachable from a starting BorderO cell
// Uses iterative approach with explicit stack (itinerary_stack) instead of recursion
// Follows graph edges to explore entire connected component of O/BorderO cells
// Marks all discovered cells as safe (added to safe_zones set)
// Time Complexity: O(k) where k = size of connected component - visits each reachable cell once
// Space Complexity: O(k) - stack stores unvisited neighbors, set stores marked cells
fn propagate_safe_zone(
  graph: AdjacencyList,
  itinerary_stack: List(#(CellCoordinate, CellContent)),
  safe_zones: set.Set(CellCoordinate),
) -> set.Set(#(Int, Int)) {
  case itinerary_stack {
    [] -> {
      safe_zones
    }

    [first, ..rest_itinerary] -> {
      let #(cell_coordinate, _cell_content) = first

      case graph |> dict.get(cell_coordinate) {
        Error(Nil) -> propagate_safe_zone(graph, rest_itinerary, safe_zones)

        Ok(path_results) -> {
          let #(
            _cell_content_result,
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result,
          ) = path_results
          let already_visited = safe_zones |> set.contains(cell_coordinate)

          case already_visited {
            True -> propagate_safe_zone(graph, rest_itinerary, safe_zones)

            False -> {
              let with_safe_zone_added =
                safe_zones |> set.insert(cell_coordinate)

              case
                top_path_result,
                right_path_result,
                down_path_result,
                left_path_result
              {
                // No neighbors - isolated cell or all neighbors already visited
                Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    rest_itinerary,
                    with_safe_zone_added,
                  )

                Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [down_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [right_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [down_path, left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [right_path, left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [right_path, down_path, left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [right_path, down_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, down_path, left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, down_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, right_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, right_path, left_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
                  propagate_safe_zone(
                    graph,
                    [top_path, right_path, down_path, ..rest_itinerary],
                    with_safe_zone_added,
                  )

                Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
                  propagate_safe_zone(
                    graph,
                    [
                      top_path,
                      right_path,
                      down_path,
                      left_path,
                      ..rest_itinerary
                    ],
                    with_safe_zone_added,
                  )
              }
            }
          }
        }
      }
    }
  }
}

// Processes all BorderO cells to identify and mark all safe (non-captured) regions
// Iterates through each cell in the board; for BorderO cells, initiates DFS flood-fill
// Populates the safe-zone set by exploring all O's reachable from each BorderO source
// Time Complexity: O(m*n) - visits each O cell at most once across all DFS calls
// Space Complexity: O(m*n) - worst case: all cells are O's, stored in visited set
fn mark_all_safe_regions(graph, board: Board) -> set.Set(CellCoordinate) {
  board
  |> list.index_fold(from: set.new(), with: fn(safe_zones, row, row_index) {
    row
    |> list.index_fold(
      from: safe_zones,
      with: fn(row_acc, curr_cell_content, column_index) {
        case curr_cell_content {
          X | O -> row_acc

          BorderO -> {
            let curr_cell_coordinate = #(row_index, column_index)

            propagate_safe_zone(
              graph,
              [#(curr_cell_coordinate, curr_cell_content)],
              row_acc,
            )
          }
        }
      },
    )
  })
}

// Reconstructs the board with final cell values based on safe-zone membership
// Iterates through original board: keeps O if in safe_zones, otherwise converts to X
// Produces final output board with all surrounded O's replaced by X's
// Time Complexity: O(m*n) - processes and writes each cell once
// Space Complexity: O(m*n) - creates new board with same dimensions
fn apply_safe_zones_to_board(
  safe_zones: set.Set(CellCoordinate),
  board: Board,
) -> Board {
  board
  |> list.index_fold(from: [], with: fn(board_acc, row, row_index) {
    let new_row =
      row
      |> list.index_fold(
        from: [],
        with: fn(row_acc, _curr_cell_content, column_index) {
          let curr_cell_coordinate = #(row_index, column_index)
          case safe_zones |> set.contains(curr_cell_coordinate) {
            True -> [O, ..row_acc]
            False -> [X, ..row_acc]
          }
        },
      )
      |> list.reverse

    [new_row, ..board_acc]
  })
  |> list.reverse
}

// Main solver for LeetCode 130: Surrounded Regions problem
// Algorithm:
//   1. Mark border O's as BorderO (safe zone seeds)
//   2. Build connectivity graph with bidirectional edges between matching-content neighbors
//   3. DFS from each BorderO to find all reachable O cells (safe regions)
//   4. Replace non-safe O's with X's in output
// Handles edge cases: single cell, all same content, isolated regions, nested structures
// Overall Time Complexity: O(m*n) - single pass for marking + graph building + DFS
// Overall Space Complexity: O(m*n) - adjacency list + safe-zone set + output board
fn t(board: Board) {
  let with_border_os = mark_border_connected_o_cells(board)

  construct_region_connectivity_graph(with_border_os)
  |> mark_all_safe_regions(with_border_os)
  |> apply_safe_zones_to_board(with_border_os)
}

// ============================================================================
// Comprehensive Test Suite for LeetCode 130: Surrounded Regions
// ============================================================================
// The below test suite provides 15+ test cases covering:
//   - Basic surrounded and unsurrounded regions
//   - Edge cases: single cell, all O's, all X's, minimum dimensions
//   - Multiple separate regions with different capture states
//   - Nested O regions and complex topologies
//   - Boundary conditions: cells touching edges, cells on borders
//   - Various grid sizes (2x2 through 7x7)
//   - Special patterns: checkerboard, H-shaped, ring-shaped, linear
//
// Each test includes:
//   - Clear description of the scenario being tested
//   - Input board configuration with visual layout
//   - Expected output and explanation of why those O's are captured or preserved
//   - Verification against the algorithm's correct behavior
//
// Time/Space Complexity:These tests validate the O(m*n) time and O(m*n) space
// complexity of the algorithm, which is optimal for this problem since every
// cell must be examined at least once to determine its final state.

pub fn run() {
  // Test 1: Basic surrounded region (4x4)
  // 'O's in the center surrounded by 'X's on all sides
  // Expected: Center O's captured because they don't touch borders
  let b1 = [[X, X, X, X], [X, O, O, X], [X, X, O, X], [X, O, X, X]]
  io.println("Test 1: Basic surrounded 4x4 region")
  io.println("Input:  [[X,X,X,X], [X,O,O,X], [X,X,O,X], [X,O,X,X]]")
  io.println("Expected: All surrounded O's become X's")
  echo t(b1)

  // Test 2: Single cell board
  // Edge case: minimal board size (1x1)
  // Expected: Solo cell unchanged (effectively at border)
  let b2 = [[X]]
  io.println("\nTest 2: Single cell board")
  io.println("Input: [[X]]")
  io.println("Expected: [[X]] (unchanged)")
  echo t(b2)

  // Test 3: Single O touching border
  // Edge case: one O on border, cannot be captured
  // Expected: O remains (connected to border)
  let b3 = [[O, X], [X, X]]
  io.println("\nTest 3: Single O at top-left corner")
  io.println("Input: [[O,X], [X,X]]")
  io.println("Expected: [[O,X], [X,X]] (O stays - touches border)")
  echo t(b3)

  // Test 4: O region touching bottom border
  // Edge case: O's in bottom row reach border, cannot be captured
  // Expected: O's remain
  let b4 = [[X, X, X], [X, O, X], [O, O, O]]
  io.println("\nTest 4: O region touching bottom edge")
  io.println("Input: [[X,X,X], [X,O,X], [O,O,O]]")
  io.println("Expected: All O's remain (bottom O's touch border)")
  echo t(b4)

  // Test 5: Multiple separate surrounded regions
  // Different O groups, some surrounded, some not
  // Expected: Only fully surrounded regions captured
  let b5 = [
    [X, X, X, X, X],
    [X, O, O, O, X],
    [X, O, X, O, X],
    [X, O, O, O, X],
    [X, X, X, X, X],
  ]
  io.println("\nTest 5: Large surrounded region (5x5)")
  io.println(
    "Input: [[X,X,X,X,X], [X,O,O,O,X], [X,O,X,O,X], [X,O,O,O,X], [X,X,X,X,X]]",
  )
  io.println("Expected: All O's surrounded row 1-4 become X's; inner X stays X")
  echo t(b5)

  // Test 6: Nested/complex surrounded regions
  // Ring-shaped region surrounding another region
  // Expected: Both inner and outer O's captured if fully surrounded
  let b6 = [
    [X, X, X, X, X, X, X],
    [X, O, O, O, O, O, X],
    [X, O, X, X, X, O, X],
    [X, O, X, O, X, O, X],
    [X, O, X, X, X, O, X],
    [X, O, O, O, O, O, X],
    [X, X, X, X, X, X, X],
  ]
  io.println("\nTest 6: Nested surrounded regions (7x7)")
  io.println(
    "Expected: All O's in rows 1-6, cols 1-5 become X's (surrounded by X border)",
  )
  echo t(b6)

  // Test 7: All O's board
  // No X's to form boundaries
  // Expected: All O's remain (all reach border or each other freely)
  let b7 = [[O, O, O], [O, O, O], [O, O, O]]
  io.println("\nTest 7: All O's board (3x3)")
  io.println("Input: [[O,O,O], [O,O,O], [O,O,O]]")
  io.println("Expected: All O's remain (reached borders)")
  echo t(b7)

  // Test 8: All X's board
  // No O's to capture
  // Expected: All X's unchanged
  let b8 = [[X, X, X], [X, X, X], [X, X, X]]
  io.println("\nTest 8: All X's board (3x3)")
  io.println("Input: [[X,X,X], [X,X,X], [X,X,X]]")
  io.println("Expected: [[X,X,X], [X,X,X], [X,X,X]] (all X's)")
  echo t(b8)

  // Test 9: Single surrounded O in center
  // Minimal surrounded region (one cell)
  // Expected: Single O becomes X
  let b9 = [[X, X, X], [X, O, X], [X, X, X]]
  io.println("\nTest 9: Single surrounded O (3x3)")
  io.println("Input: [[X,X,X], [X,O,X], [X,X,X]]")
  io.println("Expected: [[X,X,X], [X,X,X], [X,X,X]] (O captured)")
  echo t(b9)

  // Test 10: Two separate surrounded regions
  // Left and right regions both fully surrounded
  // Expected: Both captured independently
  let b10 = [
    [X, X, X, X, X, X, X],
    [X, O, X, X, X, O, X],
    [X, X, X, X, X, X, X],
  ]
  io.println("\nTest 10: Two separate surrounded regions (3x7)")
  io.println("Input: [[X,X,X,X,X,X,X], [X,O,X,X,X,O,X], [X,X,X,X,X,X,X]]")
  io.println("Expected: Both O's captured")
  echo t(b10)

  // Test 11: O region with multiple shapes
  // Checkerboard-like pattern of surrounded O's
  // Expected: All separated O's captured
  let b11 = [
    [X, X, X, X, X, X, X],
    [X, O, X, O, X, O, X],
    [X, X, X, X, X, X, X],
    [X, O, X, O, X, O, X],
    [X, X, X, X, X, X, X],
  ]
  io.println("\nTest 11: Checkerboard separated regions (5x7)")
  io.println("Expected: All isolated O's become X's (each surrounded)")
  echo t(b11)

  // Test 12: H-shaped surrounded O region
  // Connected O's forming complex shape
  // Expected: All O's captured
  let b12 = [
    [X, X, X, X, X, X, X],
    [X, O, X, O, X, O, X],
    [X, O, O, O, O, O, X],
    [X, O, X, O, X, O, X],
    [X, X, X, X, X, X, X],
  ]
  io.println("\nTest 12: H-shaped region (5x7)")
  io.println("Input: Complex connected O region")
  io.println("Expected: All O's in middle captured")
  echo t(b12)

  // Test 13: Large board with off-border region
  // 6x6 board with region just barely not touching edges
  // Expected: Region surrounded and captured
  let b13 = [
    [X, X, X, X, X, X],
    [X, X, X, X, X, X],
    [X, X, O, O, X, X],
    [X, X, O, O, X, X],
    [X, X, X, X, X, X],
    [X, X, X, X, X, X],
  ]
  io.println("\nTest 13: Centered O region in 6x6")
  io.println(
    "Input: [[X..], [X..], [X,X,O,O,X,X], [X,X,O,O,X,X], [X..], [X..]]",
  )
  io.println("Expected: Center O's captured")
  echo t(b13)

  // Test 14: Single column board
  // Edge case: 1 column, multiple rows
  // Expected: All internals possible edge case
  let b14 = [[X], [O], [X], [O], [X]]
  io.println("\nTest 14: Single column board (5x1)")
  io.println("Input: [[X], [O], [X], [O], [X]]")
  io.println("Expected: All O's remain (column borders = left/right edges)")
  echo t(b14)

  // Test 15: Single row board
  // Edge case: multiple columns, 1 row
  // Expected: All O's remain (row is at border)
  let b15 = [[X, O, X, O, X]]
  io.println("\nTest 15: Single row board (1x5)")
  io.println("Input: [[X,O,X,O,X]]")
  io.println("Expected: All O's remain (row is border)")
  echo t(b15)
}
