import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

// ============================================================================
// TYPES AND DATA STRUCTURES
// ============================================================================

/// Represents a cell location in the grid using (row, column) coordinates
type CellCoordinate =
  #(Int, Int)

/// Adjacency list representation of land cells.
/// Maps a cell coordinate to a tuple of (down neighbor, right neighbor).
/// Uses Result to indicate if a neighbor exists (Ok) or doesn't (Error).
type AdjacencyList =
  dict.Dict(
    CellCoordinate,
    #(Result(CellCoordinate, Nil), Result(CellCoordinate, Nil)),
  )

/// Tracks land cells from the previous row being processed.
/// Used during graph construction to establish vertical connections.
type PrevRowTable =
  dict.Dict(CellCoordinate, Int)

/// Updates adjacency list when current cell is land (1).
/// Establishes a right edge from left cell to current cell.
fn update_left_cell_when_current_cell_is_land(
  graph,
  left_cell_coordinate,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(descendants_maybe) {
    case descendants_maybe {
      None -> #(Error(Nil), Ok(curr_cell_coordinate))

      Some(descendants) -> {
        let #(down_cell_result, _right_cell_result) = descendants
        #(down_cell_result, Ok(curr_cell_coordinate))
      }
    }
  })
}

/// Updates adjacency list when current cell is water (0).
fn update_left_cell_when_current_cell_is_water(
  graph,
  left_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(descendants_maybe) {
    case descendants_maybe {
      None -> #(Error(Nil), Error(Nil))

      Some(descendants) -> {
        let #(down_cell_result, _right_cell_result) = descendants
        #(down_cell_result, Error(Nil))
      }
    }
  })
}

/// Updates adjacency list when current cell is land (1).
/// Establishes a down edge from top cell to current cell.
fn update_top_cell_when_current_cell_is_land(
  graph,
  top_cell_coordinate,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(descendants_maybe) {
    case descendants_maybe {
      None -> #(Ok(curr_cell_coordinate), Error(Nil))

      Some(descendants) -> {
        let #(_down_cell_result, right_cell_result) = descendants
        #(Ok(curr_cell_coordinate), right_cell_result)
      }
    }
  })
}

/// Updates adjacency list when current cell is water (0).
fn update_top_cell_when_current_cell_is_water(
  graph,
  top_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(descendants_maybe) {
    case descendants_maybe {
      None -> #(Error(Nil), Error(Nil))

      Some(descendants) -> {
        let #(_down_cell_result, right_cell_result) = descendants
        #(Error(Nil), right_cell_result)
      }
    }
  })
}

/// Initializes a new isolated island cell with no neighbors yet.
fn initialize_new_island(graph, curr_cell_coordinate) -> AdjacencyList {
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(Error(Nil), Error(Nil)))
}

/// Builds an adjacency list from the grid.
/// Processes grid row-by-row, left-to-right, connecting adjacent land cells.
/// Only connects right and down neighbors to avoid edge duplication.
///
/// Time Complexity: O(m * n) where m = rows, n = columns
/// Space Complexity: O(m * n) for the adjacency list and prev_row_table
fn build_graph(grid: List(List(Int))) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()

  let #(_prev_row_table, graph) =
    grid
    |> list.index_fold(
      from: #(initial_prev_row_table, initial_graph),
      with: fn(row_acc, row, row_index) {
        let #(prev_row_table, graph) = row_acc
        let initial_left_cell = -1

        let #(_left_cell, updated_prev_row_table, updated_graph) =
          row
          |> list.index_fold(
            from: #(initial_left_cell, prev_row_table, graph),
            with: fn(column_acc, curr_cell, column_index) {
              let #(left_cell, prev_row_table, graph) = column_acc

              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: -1)
              let curr_cell_coordinate = #(row_index, column_index)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(for: curr_cell_coordinate, insert: curr_cell)
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)

              case left_cell, top_cell, curr_cell {
                1, 1, 1 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cell_when_current_cell_is_land(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_top_cell_when_current_cell_is_land(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    ),
                )

                1, _, 1 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cell_when_current_cell_is_land(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    ),
                )

                _, 1, 1 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_top_cell_when_current_cell_is_land(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    ),
                )

                1, 1, 0 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cell_when_current_cell_is_water(
                      left_cell_coordinate,
                    )
                    |> update_top_cell_when_current_cell_is_water(
                      top_cell_coordinate,
                    ),
                )

                1, _, 0 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cell_when_current_cell_is_water(
                      left_cell_coordinate,
                    ),
                )

                _, 1, 0 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_top_cell_when_current_cell_is_water(
                      top_cell_coordinate,
                    ),
                )

                _, _, 1 -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph |> initialize_new_island(curr_cell_coordinate),
                )
                _, _, _ -> #(curr_cell, updated_prev_row_table, graph)
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

/// Performs depth-first search (DFS) to explore all cells in an island.
/// Uses a stack to traverse connected land cells and removes them from the graph.
///
/// Time Complexity: O(k) where k = number of cells in the island
/// Space Complexity: O(k) for the stack in worst case (long chain of cells)
fn explore_island(
  graph: AdjacencyList,
  to_be_visited_stack: List(CellCoordinate),
) -> AdjacencyList {
  case to_be_visited_stack {
    // Base case: island fully explored
    [] -> graph

    [coordinate, ..rest] ->
      case graph |> dict.get(coordinate) {
        Ok(coordinates) -> {
          let #(down_coordinate_result, right_coordinate_result) = coordinates
          let updated_graph = graph |> dict.delete(coordinate)

          case down_coordinate_result, right_coordinate_result {
            // Leaf node: no unvisited neighbors
            Error(Nil), Error(Nil) -> explore_island(updated_graph, rest)

            Error(Nil), Ok(right_coordinate) ->
              explore_island(updated_graph, [right_coordinate, ..rest])

            Ok(down_coordinate), Error(Nil) ->
              explore_island(updated_graph, [down_coordinate, ..rest])

            Ok(down_coordinate), Ok(right_coordinate) ->
              explore_island(updated_graph, [
                right_coordinate,
                down_coordinate,
                ..rest
              ])
          }
        }

        Error(Nil) -> explore_island(graph, rest)
      }
  }
}

/// Counts total islands by exploring each undiscovered island via DFS.
/// Iterates through grid and increments count for each new island found.
///
/// Time Complexity: O(m * n) - visits each cell once
/// Space Complexity: O(m * n) for the graph (gradually emptied during exploration)
fn count_number_of_islands(graph: AdjacencyList, grid: List(List(Int))) -> Int {
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

/// Main algorithm: counts distinct islands in the grid.
/// 1. Builds adjacency list representation
/// 2. Counts islands using DFS exploration
///
/// Overall Time Complexity: O(m * n) where m = rows, n = columns
/// Overall Space Complexity: O(m * n) for the adjacency list and call stack
fn t(grid: List(List(Int))) -> Int {
  build_graph(grid) |> count_number_of_islands(grid)
}

/// Executes comprehensive test suite for the islands algorithm.
pub fn run() {
  // Test 1: Expected 1 island (large connected component)
  let g1 = [
    [1, 1, 1, 1, 0],
    [1, 1, 0, 1, 0],
    [1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0],
  ]
  io.println("Test 1 - One large island: " <> string.inspect(t(g1)))

  // Test 2: Expected 3 islands
  let g2 = [
    [1, 1, 0, 0, 0],
    [1, 1, 0, 0, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 0, 1, 1],
  ]
  io.println("Test 2 - Three islands: " <> string.inspect(t(g2)))

  // Test 3: Expected 3 islands
  let g3 = [
    [1, 1, 0, 0, 0],
    [1, 1, 0, 0, 0],
    [0, 0, 1, 0, 0],
    [0, 0, 0, 0, 1],
  ]
  io.println("Test 3 - Three islands: " <> string.inspect(t(g3)))

  // Test 4: Expected 0 islands (all water)
  let g4 = [
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
  ]
  io.println("Test 4 - All water: " <> string.inspect(t(g4)))

  // Test 5: Expected 1 island (all land)
  let g5 = [
    [1, 1, 1],
    [1, 1, 1],
    [1, 1, 1],
  ]
  io.println("Test 5 - All land: " <> string.inspect(t(g5)))

  // Test 6: Expected 1 island (single cell)
  let g6 = [[1]]
  io.println("Test 6 - Single land cell: " <> string.inspect(t(g6)))

  // Test 7: Expected 0 islands (single water cell)
  let g7 = [[0]]
  io.println("Test 7 - Single water cell: " <> string.inspect(t(g7)))

  // Test 8: Expected 8 islands (checkerboard pattern)
  let g8 = [
    [1, 0, 1, 0, 1],
    [0, 1, 0, 1, 0],
    [1, 0, 1, 0, 1],
  ]
  io.println("Test 8 - Checkerboard: " <> string.inspect(t(g8)))

  // Test 9: Expected 2 islands (diagonal touching - should NOT count as one)
  let g9 = [
    [1, 0],
    [0, 1],
  ]
  io.println("Test 9 - Diagonal islands: " <> string.inspect(t(g9)))

  // Test 10: Expected 1 island (complex L-shape)
  let g10 = [
    [1, 1, 0, 0],
    [0, 1, 0, 0],
    [0, 1, 1, 1],
    [0, 0, 0, 1],
  ]
  io.println("Test 10 - L-shaped island: " <> string.inspect(t(g10)))

  // Test 11: Expected 4 islands (4 corners)
  let g11 = [
    [1, 0, 0, 1],
    [0, 0, 0, 0],
    [0, 0, 0, 0],
    [1, 0, 0, 1],
  ]
  io.println("Test 11 - Four corner islands: " <> string.inspect(t(g11)))

  // Test 12: Expected 1 island (snake pattern)
  let g12 = [
    [1, 1, 0, 0],
    [0, 1, 1, 0],
    [0, 0, 1, 1],
  ]
  io.println("Test 12 - Snake pattern: " <> string.inspect(t(g12)))
}
