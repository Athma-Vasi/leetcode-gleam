import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

// ============================================================================
// TYPES AND DATA STRUCTURES
// ============================================================================

/// Grid of booleans where True = land, False = water.
/// Size: m rows by n columns.
type Grid =
  List(List(Bool))

/// Coordinate of a grid cell represented as (row, column).
type CellCoordinate =
  #(Int, Int)

type TopPathResult =
  Result(CellCoordinate, Nil)

type RightPathResult =
  TopPathResult

type DownPathResult =
  RightPathResult

type LeftPathResult =
  DownPathResult

/// Adjacency list linking a land cell to its orthogonal neighbors.
/// Each neighbor uses Result to indicate presence (Ok) or absence (Error).
type AdjacencyList =
  dict.Dict(
    CellCoordinate,
    #(TopPathResult, RightPathResult, DownPathResult, LeftPathResult),
  )

/// Tracks the previous row's cell states during graph construction for top lookups.
type PrevRowTable =
  dict.Dict(CellCoordinate, Bool)

/// Records a top neighbor for the current land cell if present.
fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  top_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only top neighbor
      None -> #(Ok(top_cell_coordinate), Error(Nil), Error(Nil), Error(Nil))

      // Cell already has other neighbors: update only the top neighbor
      Some(path_results) -> {
        let #(
          _top_path_result,
          right_path_result,
          down_path_result,
          left_path_result,
        ) = path_results

        #(
          Ok(top_cell_coordinate),
          right_path_result,
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

/// Records a left neighbor for the current land cell if present.
fn update_current_cells_left_path(
  graph,
  curr_cell_coordinate,
  left_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only left neighbor
      None -> #(Error(Nil), Error(Nil), Error(Nil), Ok(left_cell_coordinate))

      // Cell already has other neighbors: update only the left neighbor
      Some(path_results) -> {
        let #(
          top_path_result,
          right_path_result,
          down_path_result,
          _left_path_result,
        ) = path_results

        #(
          top_path_result,
          right_path_result,
          down_path_result,
          Ok(left_cell_coordinate),
        )
      }
    }
  })
}

/// Connects the left land cell's right edge to the current cell.
fn update_left_cells_right_path(
  graph,
  left_cell_coordinate,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Left cell already exists: it must be land, so add the right neighbor
      None -> #(Error(Nil), Ok(curr_cell_coordinate), Error(Nil), Error(Nil))

      // Left cell already exists: update its right neighbor
      Some(path_results) -> {
        let #(
          top_path_result,
          _right_path_result,
          down_path_result,
          left_path_result,
        ) = path_results

        #(
          top_path_result,
          Ok(curr_cell_coordinate),
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

/// Connects the top land cell's down edge to the current cell.
fn update_top_cells_down_path(
  graph,
  top_cell_coordinate,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Top cell already exists: it must be land, so add the down neighbor
      None -> #(Error(Nil), Error(Nil), Ok(curr_cell_coordinate), Error(Nil))

      // Top cell already exists: update its down neighbor
      Some(path_results) -> {
        let #(
          top_path_result,
          right_path_result,
          _down_path_result,
          left_path_result,
        ) = path_results

        #(
          top_path_result,
          right_path_result,
          Ok(curr_cell_coordinate),
          left_path_result,
        )
      }
    }
  })
}

/// Seeds a fresh land cell with no neighbors yet.
fn initialize_new_island(graph, curr_cell_coordinate) -> AdjacencyList {
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
  ))
}

/// Builds a bidirectional adjacency list for all land cells using a single pass.
/// Time: O(m * n); Space: O(m * n) for graph plus prev-row bookkeeping.
fn build_graph(grid: Grid) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()

  // Iterate through each row, maintaining previous row state for top neighbor lookup
  let #(_prev_row_table, graph) =
    grid
    |> list.index_fold(
      from: #(initial_prev_row_table, initial_graph),
      with: fn(row_acc, row, row_index) {
        let #(prev_row_table, graph) = row_acc
        // Sentinel value representing no left cell at row start
        let initial_left_cell = False

        let #(_left_cell, updated_prev_row_table, updated_graph) =
          row
          |> list.index_fold(
            from: #(initial_left_cell, prev_row_table, graph),
            with: fn(column_acc, curr_cell, column_index) {
              let #(left_cell, prev_row_table, graph) = column_acc

              // Retrieve the land/water state of the cell above current position
              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: False)

              // Record current cell's land/water state for next row's lookups
              let curr_cell_coordinate = #(row_index, column_index)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(for: curr_cell_coordinate, insert: curr_cell)
                // Discard top cell reference; we've moved past this row
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)

              case left_cell, top_cell, curr_cell {
                // Current cell is land with land neighbors above and to the left
                True, True, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_top_cells_down_path(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_left_path(
                      curr_cell_coordinate,
                      left_cell_coordinate,
                    )
                    |> update_current_cells_top_path(
                      curr_cell_coordinate,
                      top_cell_coordinate,
                    ),
                )

                // Current cell is land with only a left neighbor
                True, False, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_left_path(
                      curr_cell_coordinate,
                      left_cell_coordinate,
                    ),
                )

                // Current cell is land with only a top neighbor
                False, True, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_top_cells_down_path(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_top_path(
                      curr_cell_coordinate,
                      top_cell_coordinate,
                    ),
                )

                // Current cell is land with no connected neighbors; start new island
                False, False, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> initialize_new_island(curr_cell_coordinate),
                )

                // Current cell is water; no action needed
                False, True, False
                | True, False, False
                | True, True, False
                | False, False, False
                -> #(curr_cell, updated_prev_row_table, graph)
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

/// Iterative DFS that removes a discovered island from the graph.
/// Time: O(k) for island size k; Space: O(k) for stack depth.
fn explore_island(
  graph: AdjacencyList,
  itinerary_stack: List(CellCoordinate),
) -> AdjacencyList {
  case itinerary_stack {
    // Island exploration complete
    [] -> graph

    [coordinate, ..rest] ->
      case graph |> dict.get(coordinate) {
        // Current cell is in graph (land); extract its neighbors
        Ok(coordinates) -> {
          let #(
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result,
          ) = coordinates
          // Mark cell as visited by removing it from graph
          let updated_graph = graph |> dict.delete(coordinate)

          // Push all unvisited neighbors onto stack based on available connections
          case
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result
          {
            // Isolated cell with no neighbors
            Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, rest)

            // Only left neighbor
            Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
              explore_island(updated_graph, [left_path, ..rest])

            // Only down neighbor
            Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
              explore_island(updated_graph, [down_path, ..rest])

            // Only right neighbor
            Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [right_path, ..rest])

            // Only top neighbor
            Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [top_path, ..rest])

            // Down and left neighbors
            Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
              explore_island(updated_graph, [down_path, left_path, ..rest])

            // Right and left neighbors
            Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
              explore_island(updated_graph, [right_path, left_path, ..rest])

            // Right, down, and left neighbors
            Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
              explore_island(updated_graph, [
                right_path,
                down_path,
                left_path,
                ..rest
              ])

            // Right and down neighbors
            Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
              explore_island(updated_graph, [right_path, down_path, ..rest])

            // Top and left neighbors
            Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
              explore_island(updated_graph, [top_path, left_path, ..rest])

            // Top, down, and left neighbors
            Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
              explore_island(updated_graph, [
                top_path,
                down_path,
                left_path,
                ..rest
              ])

            // Top and down neighbors
            Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
              explore_island(updated_graph, [top_path, down_path, ..rest])

            // Top and right neighbors
            Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [top_path, right_path, ..rest])

            // Top, right, and left neighbors
            Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
              explore_island(updated_graph, [
                top_path,
                right_path,
                left_path,
                ..rest
              ])

            // Top, right, and down neighbors
            Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
              explore_island(updated_graph, [
                top_path,
                right_path,
                down_path,
                ..rest
              ])

            // All four neighbors
            Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
              explore_island(updated_graph, [
                top_path,
                right_path,
                down_path,
                left_path,
                ..rest
              ])
          }
        }

        // Current cell not in graph; it's already been visited or is water
        Error(Nil) -> explore_island(graph, rest)
      }
  }
}

/// Scans all cells, launching DFS for each unvisited land cell to count islands.
/// Time: O(m * n); Space: O(m * n) for the adjacency list (shrinks as we visit).
fn count_number_of_islands(graph: AdjacencyList, grid: Grid) -> Int {
  let initial_count = 0

  let #(count, _empty_graph) =
    grid
    |> list.index_fold(
      from: #(initial_count, graph),
      with: fn(row_acc, row, row_index) {
        let #(count, graph) = row_acc

        row
        |> list.index_fold(
          from: #(count, graph),
          with: fn(column_acc, _cell, column_index) {
            let #(count, graph) = column_acc
            let coordinate = #(row_index, column_index)

            case graph |> dict.has_key(coordinate) {
              True -> #(count + 1, explore_island(graph, [coordinate]))

              False -> #(count, graph)
            }
          },
        )
      },
    )

  count
}

/// Public entry: builds adjacency graph then counts distinct islands.
/// Time: O(m * n); Space: O(m * n).
fn t(grid: Grid) -> Int {
  build_graph(grid) |> count_number_of_islands(grid)
}

/// Manual regression tests spanning common island configurations.
pub fn run() {
  // Test 1: Expected 1 island (large connected component)
  let g1 = [
    [True, True, True, True, False],
    [True, True, False, True, False],
    [True, True, False, False, False],
    [False, False, False, False, False],
  ]
  io.println("Test 1 - One large island: " <> string.inspect(t(g1)))

  // Test 2: Expected 3 islands
  let g2 = [
    [True, True, False, False, False],
    [True, True, False, False, False],
    [False, False, True, False, False],
    [False, False, False, True, True],
  ]
  io.println("Test 2 - Three islands: " <> string.inspect(t(g2)))

  // Test 3: Expected 3 islands
  let g3 = [
    [True, True, False, False, False],
    [True, True, False, False, False],
    [False, False, True, False, False],
    [False, False, False, False, True],
  ]
  io.println("Test 3 - Three islands: " <> string.inspect(t(g3)))

  // Test 4: Expected 0 islands (all water)
  let g4 = [
    [False, False, False, False],
    [False, False, False, False],
    [False, False, False, False],
  ]
  io.println("Test 4 - All water: " <> string.inspect(t(g4)))

  // Test 5: Expected 1 island (all land)
  let g5 = [
    [True, True, True],
    [True, True, True],
    [True, True, True],
  ]
  io.println("Test 5 - All land: " <> string.inspect(t(g5)))

  // Test 6: Expected 1 island (single cell)
  let g6 = [[True]]
  io.println("Test 6 - Single land cell: " <> string.inspect(t(g6)))

  // Test 7: Expected 0 islands (single water cell)
  let g7 = [[False]]
  io.println("Test 7 - Single water cell: " <> string.inspect(t(g7)))

  // Test 8: Expected 8 islands (checkerboard pattern)
  let g8 = [
    [True, False, True, False, True],
    [False, True, False, True, False],
    [True, False, True, False, True],
  ]
  io.println("Test 8 - Checkerboard: " <> string.inspect(t(g8)))

  // Test 9: Expected 2 islands (diagonal touching - should NOT count as one)
  let g9 = [
    [True, False],
    [False, True],
  ]
  io.println("Test 9 - Diagonal islands: " <> string.inspect(t(g9)))

  // Test 10: Expected 1 island (complex L-shape)
  let g10 = [
    [True, True, False, False],
    [False, True, False, False],
    [False, True, True, True],
    [False, False, False, True],
  ]
  io.println("Test 10 - L-shaped island: " <> string.inspect(t(g10)))

  // Test 11: Expected 4 islands (4 corners)
  let g11 = [
    [True, False, False, True],
    [False, False, False, False],
    [False, False, False, False],
    [True, False, False, True],
  ]
  io.println("Test 11 - Four corner islands: " <> string.inspect(t(g11)))

  // Test 12: Expected 1 island (snake pattern)
  let g12 = [
    [True, True, False, False],
    [False, True, True, False],
    [False, False, True, True],
  ]
  io.println("Test 12 - Snake pattern: " <> string.inspect(t(g12)))
}
