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

/// Set the current cell's top neighbor when current cell is land
fn update_current_cells_top_path_when_current_cell_is_land(
  graph,
  curr_cell_coordinate,
  top_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(Ok(top_cell_coordinate), Error(Nil), Error(Nil), Error(Nil))

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

/// Set the current cell's left neighbor when current cell is land
fn update_current_cells_left_path_when_current_cell_is_land(
  graph,
  curr_cell_coordinate,
  left_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(Error(Nil), Error(Nil), Error(Nil), Ok(left_cell_coordinate))

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

/// Link left cell's right neighbor to current land cell
fn update_left_cells_right_path_when_current_cell_is_land(
  graph,
  left_cell_coordinate,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(Error(Nil), Ok(curr_cell_coordinate), Error(Nil), Error(Nil))

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

/// Remove right neighbor from left cell when current cell is water
fn update_left_cells_right_path_when_current_cell_is_water(
  graph,
  left_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(Error(Nil), Error(Nil), Error(Nil), Error(Nil))

      Some(path_results) -> {
        let #(
          top_path_result,
          _right_path_result,
          down_path_result,
          left_path_result,
        ) = path_results

        #(top_path_result, Error(Nil), down_path_result, left_path_result)
      }
    }
  })
}

/// Link top cell's down neighbor to current land cell
fn update_top_cells_down_path_when_current_cell_is_land(
  graph,
  top_cell_coordinate,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(Error(Nil), Error(Nil), Ok(curr_cell_coordinate), Error(Nil))

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

/// Remove down neighbor from top cell when current cell is water
fn update_top_cells_down_path_when_current_cell_is_water(
  graph,
  top_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(Error(Nil), Error(Nil), Error(Nil), Error(Nil))

      Some(path_results) -> {
        let #(
          top_path_result,
          right_path_result,
          _down_path_result,
          left_path_result,
        ) = path_results

        #(top_path_result, right_path_result, Error(Nil), left_path_result)
      }
    }
  })
}

/// Seed a brand new island node with no neighbors
fn initialize_new_island(graph, curr_cell_coordinate) -> AdjacencyList {
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
  ))
}

/// Ensure the final cell is present in the graph even if isolated
fn add_last_cell(graph, curr_cell_coordinate) -> AdjacencyList {
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
  ))
}

/// Build adjacency list for all land cells, connecting orthogonal neighbors
/// Time: O(m * n) where m,n are grid dimensions (single pass)
/// Space: O(m * n) for graph + prev row bookkeeping
fn build_graph(grid: Grid) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()
  let number_of_rows = list.length(grid)

  let #(_prev_row_table, graph) =
    grid
    |> list.index_fold(
      from: #(initial_prev_row_table, initial_graph),
      with: fn(row_acc, row, row_index) {
        let #(prev_row_table, graph) = row_acc
        let initial_left_cell = False
        let number_of_columns = list.length(row)

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
                |> result.unwrap(or: False)
              let curr_cell_coordinate = #(row_index, column_index)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(for: curr_cell_coordinate, insert: curr_cell)
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)
              let is_last_cell =
                row_index == number_of_rows - 1
                && column_index == number_of_columns - 1

              case left_cell, top_cell, curr_cell, is_last_cell {
                True, True, True, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path_when_current_cell_is_land(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_top_cells_down_path_when_current_cell_is_land(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_left_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      left_cell_coordinate,
                    )
                    |> update_current_cells_top_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      top_cell_coordinate,
                    )
                    |> add_last_cell(curr_cell_coordinate),
                )
                True, True, True, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path_when_current_cell_is_land(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_top_cells_down_path_when_current_cell_is_land(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_left_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      left_cell_coordinate,
                    )
                    |> update_current_cells_top_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      top_cell_coordinate,
                    ),
                )

                True, False, True, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path_when_current_cell_is_land(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_left_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      left_cell_coordinate,
                    )
                    |> add_last_cell(curr_cell_coordinate),
                )
                True, False, True, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path_when_current_cell_is_land(
                      left_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_left_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      left_cell_coordinate,
                    ),
                )

                False, True, True, True -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_top_cells_down_path_when_current_cell_is_land(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_top_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      top_cell_coordinate,
                    )
                    |> add_last_cell(curr_cell_coordinate),
                )
                False, True, True, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_top_cells_down_path_when_current_cell_is_land(
                      top_cell_coordinate,
                      curr_cell_coordinate,
                    )
                    |> update_current_cells_top_path_when_current_cell_is_land(
                      curr_cell_coordinate,
                      top_cell_coordinate,
                    ),
                )

                True, True, False, True | True, True, False, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path_when_current_cell_is_water(
                      left_cell_coordinate,
                    )
                    |> update_top_cells_down_path_when_current_cell_is_water(
                      top_cell_coordinate,
                    ),
                )

                True, False, False, True | True, False, False, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_left_cells_right_path_when_current_cell_is_water(
                      left_cell_coordinate,
                    ),
                )

                False, True, False, True | False, True, False, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> update_top_cells_down_path_when_current_cell_is_water(
                      top_cell_coordinate,
                    ),
                )

                False, False, True, True | False, False, True, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph
                    |> initialize_new_island(curr_cell_coordinate),
                )

                False, False, False, True | False, False, False, False -> #(
                  curr_cell,
                  updated_prev_row_table,
                  graph,
                )
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

/// DFS over one island; returns its area and prunes visited nodes from graph
/// Time: O(k) where k is island size
/// Space: O(k) for recursion/stack depth in worst case
fn explore_island(
  graph: AdjacencyList,
  to_be_visited_stack: List(CellCoordinate),
  area: Int,
) -> #(Int, AdjacencyList) {
  case to_be_visited_stack {
    // Base case: island fully explored
    [] -> #(area, graph)

    [coordinate, ..rest] ->
      case graph |> dict.get(coordinate) {
        Ok(coordinates) -> {
          let #(
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result,
          ) = coordinates
          let updated_graph = graph |> dict.delete(coordinate)

          case
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result
          {
            Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, rest, area + 1)

            Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
              explore_island(updated_graph, [left_path, ..rest], area + 1)

            Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
              explore_island(updated_graph, [down_path, ..rest], area + 1)

            Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [right_path, ..rest], area + 1)

            Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
              explore_island(updated_graph, [top_path, ..rest], area + 1)

            Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [down_path, left_path, ..rest],
                area + 1,
              )

            Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
              explore_island(
                updated_graph,
                [right_path, left_path, ..rest],
                area + 1,
              )

            Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [right_path, down_path, left_path, ..rest],
                area + 1,
              )

            Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
              explore_island(
                updated_graph,
                [right_path, down_path, ..rest],
                area + 1,
              )

            Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, left_path, ..rest],
                area + 1,
              )

            Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, down_path, left_path, ..rest],
                area + 1,
              )

            Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
              explore_island(
                updated_graph,
                [top_path, down_path, ..rest],
                area + 1,
              )

            Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
              explore_island(
                updated_graph,
                [top_path, right_path, ..rest],
                area + 1,
              )

            Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, right_path, left_path, ..rest],
                area + 1,
              )

            Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
              explore_island(
                updated_graph,
                [top_path, right_path, down_path, ..rest],
                area + 1,
              )

            Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
              explore_island(
                updated_graph,
                [top_path, right_path, down_path, left_path, ..rest],
                area + 1,
              )
          }
        }

        Error(Nil) -> explore_island(graph, rest, area)
      }
  }
}

/// Scan grid to find the maximum island area using the adjacency list
/// Time: O(m * n) — each cell visited at most once across all DFS traversals
/// Space: O(m * n) for the adjacency list, shrinking as islands are removed
fn find_max_island_area(graph: AdjacencyList, grid: Grid) -> Int {
  let initial_max_island_area = 0

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

            case graph |> dict.has_key(coordinate) {
              True -> {
                let #(curr_island_area, updated_graph) =
                  explore_island(graph, [coordinate], 0)

                case max_island_area > curr_island_area {
                  True -> #(max_island_area, updated_graph)
                  False -> #(curr_island_area, updated_graph)
                }
              }

              False -> #(max_island_area, graph)
            }
          },
        )
      },
    )

  max_island_area
}

/// Entry for solution: build graph then compute max island area
/// Time: O(m * n) end-to-end; Space: O(m * n)
fn t(grid: Grid) -> Int {
  build_graph(grid) |> find_max_island_area(grid)
}

/// Manual test harness with varied scenarios
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

  // Test 12: Multiple islands of same size
  let g12 = [
    [True, True, False, True, True],
    [True, False, False, True, False],
    [False, False, False, False, False],
  ]
  // Expected: 3
  io.println("Test 12 - Multiple islands same size: " <> string.inspect(t(g12)))
}
