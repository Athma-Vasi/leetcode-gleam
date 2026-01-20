import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// Grid representation as rows of booleans (True = land, False = water)
type Grid =
  List(List(Bool))

/// Coordinate of a cell as (row, column)
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

/// Adjacency list mapping each land cell to its neighbors in order:
/// Result indicates presence (Ok) or absence (Error).
type AdjacencyList =
  dict.Dict(
    CellCoordinate,
    #(TopPathResult, RightPathResult, DownPathResult, LeftPathResult),
  )

/// Tracks land/water values for the previous row during graph construction
type PrevRowTable =
  dict.Dict(CellCoordinate, Bool)

/// Updates the current cell's adjacency entry to link its top neighbor.
/// Called when the current cell is land and a land cell exists above it.
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

/// Updates the current cell's adjacency entry to link its left neighbor.
/// Called when the current cell is land and a land cell exists to its left.
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

/// Updates the left cell's adjacency entry to link its right neighbor to the current cell.
/// Called when processing a land cell that has land to its left.
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

/// Updates the top cell's adjacency entry to link its down neighbor to the current cell.
/// Called when processing a land cell that has land above it.
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

/// Initializes a new isolated land cell with no connected neighbors.
/// Called when a land cell has no land neighbors above or to its left.
fn initialize_new_island(graph, curr_cell_coordinate) -> AdjacencyList {
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
  ))
}

/// Constructs a bidirectional adjacency list graph from the grid.
/// Scans left-to-right, top-to-bottom, creating edges only between adjacent land cells.
/// Only examines top and left neighbors during forward scan (right and down edges are
/// bidirectionally created when those cells are processed).
/// Time: O(m * n) where m,n are grid dimensions (single pass)
/// Space: O(m * n) for graph + prev row bookkeeping
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

/// Performs iterative depth-first search on a single island to compute its area.
/// Uses an explicit stack to avoid deep recursion. Removes visited cells from the
/// graph to mark them as processed.
/// Time: O(k) where k is island size
/// Space: O(k) for recursion/stack depth in worst case
fn explore_island(
  graph: AdjacencyList,
  itinerary_stack: List(CellCoordinate),
  area: Int,
) -> #(Int, AdjacencyList) {
  case itinerary_stack {
    // Island exploration complete
    [] -> #(area, graph)

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
          let updated_area = area + 1

          // Push all unvisited neighbors onto stack based on available connections
          case
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result
          {
            // Isolated cell with no neighbors
            Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, rest, updated_area)

            // Only left neighbor
            Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
              explore_island(updated_graph, [left_path, ..rest], updated_area)

            // Only down neighbor
            Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
              explore_island(updated_graph, [down_path, ..rest], updated_area)

            // Only right neighbor
            Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [right_path, ..rest], updated_area)

            // Only top neighbor
            Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [top_path, ..rest], updated_area)

            // Down and left neighbors
            Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [down_path, left_path, ..rest],
                updated_area,
              )

            // Right and left neighbors
            Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
              explore_island(
                updated_graph,
                [right_path, left_path, ..rest],
                updated_area,
              )

            // Right, down, and left neighbors
            Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [right_path, down_path, left_path, ..rest],
                updated_area,
              )

            // Right and down neighbors
            Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
              explore_island(
                updated_graph,
                [right_path, down_path, ..rest],
                updated_area,
              )

            // Top and left neighbors
            Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, left_path, ..rest],
                updated_area,
              )

            // Top, down, and left neighbors
            Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, down_path, left_path, ..rest],
                updated_area,
              )

            // Top and down neighbors
            Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
              explore_island(
                updated_graph,
                [top_path, down_path, ..rest],
                updated_area,
              )

            // Top and right neighbors
            Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
              explore_island(
                updated_graph,
                [top_path, right_path, ..rest],
                updated_area,
              )

            // Top, right, and left neighbors
            Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, right_path, left_path, ..rest],
                updated_area,
              )

            // Top, right, and down neighbors
            Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
              explore_island(
                updated_graph,
                [top_path, right_path, down_path, ..rest],
                updated_area,
              )

            // All four neighbors
            Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, right_path, down_path, left_path, ..rest],
                updated_area,
              )
          }
        }

        // Current cell not in graph; it's already been visited or is water
        Error(Nil) -> explore_island(graph, rest, area)
      }
  }
}

/// Scans the entire grid to identify all islands and find the maximum area.
/// For each unvisited land cell encountered, initiates an island exploration.
/// Time: O(m * n) — each cell visited at most once across all DFS traversals
/// Space: O(m * n) for the adjacency list, shrinking as islands are removed
fn find_max_island_area(graph: AdjacencyList, grid: Grid) -> Int {
  let initial_max_island_area = 0

  // Iterate through grid to find undiscovered islands
  let #(max_island_area, _empty_graph) =
    grid
    |> list.index_fold(
      from: #(initial_max_island_area, graph),
      with: fn(row_acc, row, row_index) {
        let #(max_island_area, graph) = row_acc

        row
        |> list.index_fold(
          from: #(max_island_area, graph),
          with: fn(column_acc, _cell, column_index) {
            let #(max_island_area, graph) = column_acc
            let coordinate = #(row_index, column_index)

            // Check if this cell is an undiscovered land cell
            case graph |> dict.has_key(coordinate) {
              True -> {
                // Explore the island starting from this cell
                let #(curr_island_area, updated_graph) =
                  explore_island(graph, [coordinate], 0)

                // Update maximum area if current island is larger
                case max_island_area > curr_island_area {
                  True -> #(max_island_area, updated_graph)
                  False -> #(curr_island_area, updated_graph)
                }
              }

              // Cell is water or already visited
              False -> #(max_island_area, graph)
            }
          },
        )
      },
    )

  max_island_area
}

/// Main solution entry point: constructs graph then computes maximum island area.
/// Time: O(m * n) end-to-end; Space: O(m * n)
fn t(grid: Grid) -> Int {
  build_graph(grid) |> find_max_island_area(grid)
}

/// Test harness with comprehensive test cases covering edge cases and patterns
pub fn run() {
  let g1 = [
    [
      False,
      False,
      True,
      False,
      False,
      False,
      False,
      True,
      False,
      False,
      False,
      False,
      False,
    ],
    [
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      True,
      True,
      True,
      False,
      False,
      False,
    ],
    [
      False,
      True,
      True,
      False,
      True,
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      False,
    ],
    [
      False,
      True,
      False,
      False,
      True,
      True,
      False,
      False,
      True,
      False,
      True,
      False,
      False,
    ],
    [
      False,
      True,
      False,
      False,
      True,
      True,
      False,
      False,
      True,
      True,
      True,
      False,
      False,
    ],
    [
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      True,
      False,
      False,
    ],
    [
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      True,
      True,
      True,
      False,
      False,
      False,
    ],
    [
      False,
      False,
      False,
      False,
      False,
      False,
      False,
      True,
      True,
      False,
      False,
      False,
      False,
    ],
  ]
  // Expected: 6
  io.println("Test 1 - Complex grid: " <> string.inspect(t(g1)))

  let g2 = [[False, False, False, False, False, False, False, False]]
  // Expected: 0
  io.println("Test 2 - All water: " <> string.inspect(t(g2)))

  // Test 3: Single cell island
  let g3 = [[True]]
  // Expected: 1
  io.println("Test 3 - Single land cell: " <> string.inspect(t(g3)))

  // Test 4: All land
  let g4 = [
    [True, True, True],
    [True, True, True],
    [True, True, True],
  ]
  // Expected: 9
  io.println("Test 4 - All land (3x3): " <> string.inspect(t(g4)))

  // Test 5: Single row of land
  let g5 = [[True, True, True, True, True]]
  // Expected: 5
  io.println("Test 5 - Single row of land: " <> string.inspect(t(g5)))

  // Test 6: Single column of land
  let g6 = [[True], [True], [True], [True]]
  // Expected: 4
  io.println("Test 6 - Single column of land: " <> string.inspect(t(g6)))

  // Test 7: Diagonal islands (should not connect)
  let g7 = [
    [True, False],
    [False, True],
  ]
  // Expected: 1
  io.println("Test 7 - Diagonal islands: " <> string.inspect(t(g7)))

  // Test 8: Large connected island in corner
  let g8 = [
    [True, True, False, False],
    [True, True, False, False],
    [False, False, False, False],
    [False, False, False, False],
  ]
  // Expected: 4
  io.println("Test 8 - Square island in corner: " <> string.inspect(t(g8)))

  // Test 9: Scattered single cells
  let g9 = [
    [True, False, True, False, True],
    [False, True, False, True, False],
    [True, False, True, False, True],
  ]
  // Expected: 1
  io.println("Test 9 - Scattered single cells: " <> string.inspect(t(g9)))

  // Test 10: L-shaped island
  let g10 = [
    [True, True, False],
    [False, True, False],
    [False, True, True],
  ]
  // Expected: 5
  io.println("Test 10 - L-shaped island: " <> string.inspect(t(g10)))

  // Test 11: Snake pattern
  let g11 = [
    [True, True, False, False],
    [False, True, True, False],
    [False, False, True, True],
  ]
  // Expected: 6
  io.println("Test 11 - Snake pattern: " <> string.inspect(t(g11)))

  // Test 12: Multiple islands 
  let g12 = [
    [True, True, False, True, True],
    [True, False, True, False, True],
    [False, True, True, True, False],
    [True, False, True, False, True],
    [True, True, False, True, True],
  ]
  // Expected: 5
  io.println("Test 12 - Multiple islands: " <> string.inspect(t(g12)))
}
