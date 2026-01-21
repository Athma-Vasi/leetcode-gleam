// Breadth-first expansion for "Rotting Oranges". We transform the grid into a
// graph that stores bidirectional edges to the four neighbors we care about,
// then perform a level-order traversal to track the earliest minute each fresh
// orange can be reached by rot. The helpers below only add comments; behavior
// remains unchanged.

import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

pub type CellContent {
  Empty
  Fresh
  Discard
}

// 2D grid representation; each inner list is a row.
type Grid =
  List(List(CellContent))

// Coordinate in the grid using zero-based row and column indices.
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

type CellContentResult =
  Result(CellContent, Nil)

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

type TimeElapsed =
  Int

type ItineraryQueue =
  List(#(CellCoordinate, TimeElapsed))

// Track contents of the previous row so we can wire top edges without a second
// pass over the grid.
type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  top_cell_coordinate,
) {
  // When the current cell sees a top neighbor, record that edge. All other
  // neighbor relationships for this cell remain untouched.
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only top neighbor
      None -> #(
        Ok(curr_cell_content),
        Ok(top_cell_coordinate),
        Error(Nil),
        Error(Nil),
        Error(Nil),
      )

      // Cell already has other neighbors: update only the top neighbor
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
          Ok(top_cell_coordinate),
          right_path_result,
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

fn update_current_cells_left_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  left_cell_coordinate,
) {
  // When the current cell sees a left neighbor, record that edge. All other
  // neighbor relationships for this cell remain untouched.
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only left neighbor
      None -> #(
        Ok(curr_cell_content),
        Error(Nil),
        Error(Nil),
        Error(Nil),
        Ok(left_cell_coordinate),
      )

      // Cell already has other neighbors: update only the left neighbor
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
          Ok(left_cell_coordinate),
        )
      }
    }
  })
}

fn update_left_cells_right_path(
  graph,
  left_cell_coordinate,
  left_cell_content,
  curr_cell_coordinate,
) -> AdjacencyList {
  // Mirror the connection on the already-seen left cell: add a right edge to
  // the current cell while preserving its other edges.
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Left cell already exists: it must be water, so add the right neighbor
      None -> #(
        Ok(left_cell_content),
        Error(Nil),
        Ok(curr_cell_coordinate),
        Error(Nil),
        Error(Nil),
      )

      // Left cell already exists: update its right neighbor
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
          Ok(curr_cell_coordinate),
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

fn update_top_cells_down_path(
  graph,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
) -> AdjacencyList {
  // Mirror the connection on the already-seen top cell: add a down edge to the
  // current cell while preserving its other edges.
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Top cell already exists: it must be water, so add the down neighbor
      None -> #(
        Ok(top_cell_content),
        Error(Nil),
        Error(Nil),
        Ok(curr_cell_coordinate),
        Error(Nil),
      )

      // Top cell already exists: update its down neighbor
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
          Ok(curr_cell_coordinate),
          left_path_result,
        )
      }
    }
  })
}

fn update_left_top_and_current_cells(
  graph,
  left_cell_coordinate,
  left_cell_content,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) {
  // Wire both left and top relationships for the current cell and their
  // corresponding neighbors in one pass.
  graph
  |> update_left_cells_right_path(
    left_cell_coordinate,
    left_cell_content,
    curr_cell_coordinate,
  )
  |> update_top_cells_down_path(
    top_cell_coordinate,
    top_cell_content,
    curr_cell_coordinate,
  )
  |> update_current_cells_left_path(
    curr_cell_coordinate,
    curr_cell_content,
    left_cell_coordinate,
  )
  |> update_current_cells_top_path(
    curr_cell_coordinate,
    curr_cell_content,
    top_cell_coordinate,
  )
}

fn update_left_and_current_cells(
  graph,
  left_cell_coordinate,
  left_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) {
  // Wire only the left↔current bidirectional relationship.
  graph
  |> update_left_cells_right_path(
    left_cell_coordinate,
    left_cell_content,
    curr_cell_coordinate,
  )
  |> update_current_cells_left_path(
    curr_cell_coordinate,
    curr_cell_content,
    left_cell_coordinate,
  )
}

fn update_top_and_current_cells(
  graph,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
  curr_cell_content,
) {
  // Wire only the top↔current bidirectional relationship.
  graph
  |> update_top_cells_down_path(
    top_cell_coordinate,
    top_cell_content,
    curr_cell_coordinate,
  )
  |> update_current_cells_top_path(
    curr_cell_coordinate,
    curr_cell_content,
    top_cell_coordinate,
  )
}

fn initialize_new_sea(graph, curr_cell_coordinate) -> AdjacencyList {
  // Create a standalone node for a fresh or discard cell whose neighbors will
  // be filled in when we encounter them later in the scan.
  graph
  |> dict.insert(for: curr_cell_coordinate, insert: #(
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
    Error(Nil),
  ))
}

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
        let initial_left_cell_content = Empty

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
                |> result.unwrap(or: Empty)

              let curr_cell_coordinate = #(row_index, column_index)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(
                  for: curr_cell_coordinate,
                  insert: curr_cell_content,
                )
                // Discard top cell reference; we've moved past this row
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)

              case left_cell_content, top_cell_content, curr_cell_content {
                // Creates bidirectional edges: left↔current and top↔current.
                Fresh, Fresh, Fresh
                | Fresh, Fresh, Discard
                | Discard, Fresh, Fresh
                | Fresh, Discard, Fresh
                -> #(
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

                // Creates bidirectional edge: left↔current only.
                Fresh, Empty, Fresh
                | Fresh, Empty, Discard
                | Discard, Empty, Fresh
                -> #(
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

                // Creates bidirectional edge: top↔current only.
                Empty, Fresh, Fresh
                | Empty, Fresh, Discard
                | Empty, Discard, Fresh
                -> #(
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

                // Initializes a new disconnected graph node with no edges yet.
                // Right and down edges will be added when those cells are processed.
                Empty, Empty, Fresh | Empty, Empty, Discard -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> initialize_new_sea(curr_cell_coordinate),
                )

                Fresh, Empty, Empty
                | Fresh, Fresh, Empty
                | Fresh, Discard, Empty
                | Fresh, Discard, Discard
                | Empty, Fresh, Empty
                | Empty, Empty, Empty
                | Empty, Discard, Discard
                | Empty, Discard, Empty
                | Discard, Discard, Empty
                | Discard, Discard, Fresh
                | Discard, Empty, Discard
                | Discard, Fresh, Discard
                | Discard, Empty, Empty
                | Discard, Fresh, Empty
                | Discard, Discard, Discard
                -> #(curr_cell_content, updated_prev_row_table, graph)
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

fn add_directions(
  rest_itinerary: ItineraryQueue,
  paths: List(CellCoordinate),
  new_elapsed: Int,
) {
  // Append all reachable neighbor coordinates with the same elapsed time,
  // preserving BFS layer ordering in the itinerary queue.
  paths
  |> list.fold(from: rest_itinerary, with: fn(queue, path) {
    queue |> list.append([#(path, new_elapsed)])
  })
}
