import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result

pub type CellContent {
  Treasure
  Water
  Hazard
}

type Grid =
  List(List(CellContent))

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

type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  top_cell_coordinate,
) {
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
        let initial_left_cell_content = Hazard

        let #(_left_cell_content, updated_prev_row_table, updated_graph) =
          row
          |> list.index_fold(
            from: #(initial_left_cell_content, prev_row_table, graph),
            with: fn(column_acc, curr_cell_content, column_index) {
              let #(left_cell_content, prev_row_table, graph) = column_acc

              // Retrieve the land/water state of the cell above current position
              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell_content =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: Hazard)

              // Record current cell's land/water state for next row's lookups
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
                // Current cell is navigable with navigable neighbors on both left and top sides.
                // Creates bidirectional edges: left↔current and top↔current.
                Water, Water, Water
                | Water, Water, Treasure
                | Treasure, Water, Water
                | Water, Treasure, Water
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

                // Current cell is navigable with a navigable left neighbor but hazardous top.
                // Creates bidirectional edge: left↔current only.
                // Top cell is blocked (Hazard), so no vertical connection.
                Water, Hazard, Water
                | Water, Hazard, Treasure
                | Treasure, Hazard, Water
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

                // Current cell is navigable with a navigable top neighbor but hazardous left.
                // Creates bidirectional edge: top↔current only.
                // Left cell is blocked (Hazard), so no horizontal connection.
                Hazard, Water, Water
                | Hazard, Water, Treasure
                | Hazard, Treasure, Water
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

                // Current cell is navigable but isolated (no navigable neighbors on left or top).
                // Initializes a new disconnected graph node with no edges yet.
                // Right and down edges will be added when those cells are processed.
                Hazard, Hazard, Water | Hazard, Hazard, Treasure -> #(
                  curr_cell_content,
                  updated_prev_row_table,
                  graph
                    |> initialize_new_sea(curr_cell_coordinate),
                )

                // Current cell is a Hazard OR invalid configurations (e.g., Treasure→Treasure edges).
                // No graph operations needed because:
                //   - Hazard cells are impassable obstacles
                //   - Treasure→Treasure edges violate the single-treasure assumption
                // Simply pass through without modifying the adjacency list.
                // Covers all remaining 15 configuration permutations.
                Water, Hazard, Hazard
                | Water, Water, Hazard
                | Water, Treasure, Hazard
                | Water, Treasure, Treasure
                | Hazard, Water, Hazard
                | Hazard, Hazard, Hazard
                | Hazard, Treasure, Treasure
                | Hazard, Treasure, Hazard
                | Treasure, Treasure, Hazard
                | Treasure, Treasure, Water
                | Treasure, Hazard, Treasure
                | Treasure, Water, Treasure
                | Treasure, Hazard, Hazard
                | Treasure, Water, Hazard
                | Treasure, Treasure, Treasure
                -> #(curr_cell_content, updated_prev_row_table, graph)
              }
            },
          )

        #(updated_prev_row_table, updated_graph)
      },
    )

  graph
}

fn set_sail(graph: AdjacencyList, itinerary_queue: List(#(CellCoordinate, Int))) {
  case itinerary_queue {
    [] -> #(graph, Error(Nil))

    [first, ..rest] -> {
      let #(cell_coordinate, distance) = first

      case graph |> dict.get(cell_coordinate) {
        Error(Nil) -> set_sail(graph, rest)

        Ok(path_results) -> {
          let #(
            cell_content_result,
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result,
          ) = path_results
          let updated_graph = graph
          let new_distance = distance + 1

          case cell_content_result {
            Error(Nil) -> set_sail(updated_graph, rest)

            Ok(cell_content) -> {
              case cell_content {
                Treasure -> #(updated_graph, Ok(new_distance))

                Hazard -> set_sail(updated_graph, rest)

                Water -> {
                  case
                    top_path_result,
                    right_path_result,
                    down_path_result,
                    left_path_result
                  {
                    // Isolated cell with no neighbors
                    Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
                      set_sail(updated_graph, rest)

                    // Only left neighbor
                    Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest |> list.append([#(left_path, new_distance)]),
                      )

                    // Only down neighbor
                    Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest |> list.append([#(down_path, new_distance)]),
                      )

                    // Only right neighbor
                    Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest |> list.append([#(right_path, new_distance)]),
                      )

                    // Only top neighbor
                    Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest |> list.append([#(top_path, new_distance)]),
                      )

                    // Down and left neighbors
                    Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(down_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )

                    // Right and left neighbors
                    Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(right_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )

                    // Right, down, and left neighbors
                    Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(right_path, new_distance),
                            #(down_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )

                    // Right and down neighbors
                    Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(right_path, new_distance),
                            #(down_path, new_distance),
                          ]),
                      )

                    // Top and left neighbors
                    Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )

                    // Top, down, and left neighbors
                    Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(down_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )

                    // Top and down neighbors
                    Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(down_path, new_distance),
                          ]),
                      )

                    // Top and right neighbors
                    Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(right_path, new_distance),
                          ]),
                      )

                    // Top, right, and left neighbors
                    Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(right_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )

                    // Top, right, and down neighbors
                    Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(right_path, new_distance),
                            #(down_path, new_distance),
                          ]),
                      )

                    // All four neighbors
                    Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest
                          |> list.append([
                            #(top_path, new_distance),
                            #(right_path, new_distance),
                            #(down_path, new_distance),
                            #(left_path, new_distance),
                          ]),
                      )
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

fn search_for_el_dorado(graph: AdjacencyList, grid: Grid) {
  grid
  |> list.index_fold(from: graph, with: fn(row_acc, row, row_index) {
    let graph = row_acc

    row
    |> list.index_fold(from: graph, with: fn(column_acc, _cell, column_index) {
      let graph = column_acc
      let coordinate = #(row_index, column_index)

      // Check if this cell is an undiscovered land cell
      case graph |> dict.has_key(coordinate) {
        True -> {
          todo
          // Explore water starting from this cell
        }

        // Cell is hazard or already visited
        False -> graph
      }
    })
  })
}

fn t(grid: Grid) {
  let first =
    grid
    |> list.first
    |> result.unwrap(or: [])
    |> list.first
    |> result.unwrap(or: Hazard)

  case first {
    Hazard -> -1
    Treasure -> 0
    Water -> {
      let #(_graph, distance_result) =
        build_graph(grid) |> set_sail([#(#(0, 0), 0)])

      case distance_result {
        Ok(distance) -> distance
        Error(Nil) -> -1
      }
    }
  }
}

pub fn run() {
  let g1 = [
    [Water, Water, Water, Water],
    [Hazard, Water, Hazard, Water],
    [Water, Water, Water, Water],
    [Treasure, Hazard, Hazard, Water],
  ]

  echo t(g1)
  //   |> dict.each(fn(key, value) {
  //     io.println("\n")
  //     io.println("key: " <> string.inspect(key))
  //     io.println("value: " <> string.inspect(value))
  //   })
}
