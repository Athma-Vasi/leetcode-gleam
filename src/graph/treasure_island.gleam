//// Treasure Island Pathfinding
////
//// Solves the shortest path problem on a 2D grid from top-left (0,0) to a treasure.
//// Uses BFS (breadth-first search) to guarantee the shortest distance.
//// 
//// Grid cells can be:
//// - Water: navigable safe passage
//// - Treasure: the goal destination
//// - Hazard: impassable obstacle
////
//// Algorithm approach:
//// 1. Build adjacency graph of navigable cells (plot_course)
//// 2. Perform BFS from start to treasure (set_sail)
//// 3. Return distance or -1 if unreachable
////
//// Time Complexity: O(rows × cols)
//// Space Complexity: O(rows × cols)

import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// Represents the content of a grid cell in the treasure map.
/// - Treasure: The goal location to reach
/// - Water: Navigable safe passage
/// - Hazard: Impassable obstacle (rocks, shallow waters, etc.)
pub type CellContent {
  Treasure
  Water
  Hazard
}

/// Grid of cell contents representing the treasure map.
/// Organized as rows (outer list) of columns (inner lists).
type Grid =
  List(List(CellContent))

/// Location in the grid using zero-indexed (row, column) coordinates.
type CellCoordinate =
  #(Int, Int)

/// Result indicating presence (Ok) or absence (Error) of a neighbor above.
type TopPathResult =
  Result(CellCoordinate, Nil)

/// Result indicating presence (Ok) or absence (Error) of a neighbor to the right.
type RightPathResult =
  TopPathResult

/// Result indicating presence (Ok) or absence (Error) of a neighbor below.
type DownPathResult =
  RightPathResult

/// Result indicating presence (Ok) or absence (Error) of a neighbor to the left.
type LeftPathResult =
  DownPathResult

/// Result wrapping the content of a cell.
type CellContentResult =
  Result(CellContent, Nil)

/// Adjacency list mapping each navigable cell to its content and four neighbors.
/// Tuple structure: (content, top, right, down, left)
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

/// Accumulated step count from starting position to a cell.
/// Increments by 1 for each cell traversed during BFS exploration.
type Distance =
  Int

/// Queue of cells to explore during BFS, paired with their distances from start.
/// FIFO structure: dequeue from front, enqueue neighbors at back.
type ItineraryQueue =
  List(#(CellCoordinate, Distance))

/// Temporary storage for the previous row's cell contents during graph construction.
/// Allows efficient lookup of top neighbors without scanning the entire grid.
type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

/// Links the current cell to its top neighbor in the adjacency graph.
/// Creates or updates the current cell's top edge.
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

/// Links the current cell to its left neighbor in the adjacency graph.
/// Creates or updates the current cell's left edge.
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

/// Establishes bidirectional connection by updating the left cell's right edge.
/// Called when current cell has a navigable left neighbor.
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

/// Establishes bidirectional connection by updating the top cell's down edge.
/// Called when current cell has a navigable top neighbor.
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

/// Convenience function to connect current cell to both left and top neighbors.
/// Executes all four edge updates to create bidirectional connections in both directions.
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

/// Convenience function to connect current cell to left neighbor only.
/// Used when top neighbor is not navigable (hazard).
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

/// Convenience function to connect current cell to top neighbor only.
/// Used when left neighbor is not navigable (hazard).
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

/// Initializes an isolated navigable cell with no neighbors yet discovered.
/// Right and down connections will be added when those cells are processed later.
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

/// Constructs a bidirectional adjacency graph from the treasure map grid.
/// Processes cells left-to-right, top-to-bottom in a single pass.
/// Only connects navigable cells (Water/Treasure), skipping Hazards.
/// Time: O(rows × cols) - single pass through all cells
/// Space: O(rows × cols) for adjacency list storage
fn plot_course(grid: Grid) -> AdjacencyList {
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

/// Convenience function to append multiple neighbor cells to the BFS queue.
/// Takes a list of unvisited neighbor coordinates and enqueues each with the new distance.
/// Reduces code repetition in set_sail's 16 neighbor configuration cases.
/// Note: Each list.append operation is O(queue_length), making this O(neighbors × queue_length).
/// With at most 4 neighbors, this is O(queue_length) per call.
fn add_directions(
  rest_itinerary: ItineraryQueue,
  paths: List(CellCoordinate),
  new_distance: Int,
) {
  paths
  |> list.fold(from: rest_itinerary, with: fn(queue, path) {
    queue |> list.append([#(path, new_distance)])
  })
}

/// Performs breadth-first search (BFS) to find shortest path from start to treasure.
/// Uses a queue (FIFO) to explore cells level-by-level, ensuring shortest distance.
/// Removes visited cells from graph to prevent revisiting.
/// Returns Ok(distance) if treasure found, Error(Nil) if unreachable.
/// Time: O((rows × cols)²) - each cell processed once, but list.append to queue is O(queue_length)
/// Space: O(rows × cols) for adjacency list and queue storage
fn set_sail(graph: AdjacencyList, itinerary_queue: ItineraryQueue) {
  case itinerary_queue {
    // Queue exhausted without finding treasure - no valid path exists
    [] -> Error(Nil)

    [first, ..rest_itinerary] -> {
      // Dequeue next cell to explore with its accumulated distance
      let #(cell_coordinate, distance) = first

      case graph |> dict.get(cell_coordinate) {
        // Cell already visited or doesn't exist in graph - skip it
        Error(Nil) -> set_sail(graph, rest_itinerary)

        // Cell found in graph - process it
        Ok(path_results) -> {
          // Extract cell content and all four neighbor connections
          let #(
            cell_content_result,
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result,
          ) = path_results
          // Mark cell as visited by removing from graph (prevents cycles)
          let updated_graph = graph |> dict.delete(cell_coordinate)
          // Distance to any neighbor is one step further
          let new_distance = distance + 1

          case cell_content_result {
            // Malformed cell content - skip and continue
            Error(Nil) -> set_sail(updated_graph, rest_itinerary)

            Ok(cell_content) ->
              case cell_content {
                // Found the treasure! Return the distance traveled
                Treasure -> Ok(distance)

                // Should never reach hazard (filtered during graph construction)
                Hazard -> set_sail(updated_graph, rest_itinerary)

                // Navigable water cell - enqueue all unvisited neighbors
                Water -> {
                  case
                    top_path_result,
                    right_path_result,
                    down_path_result,
                    left_path_result
                  {
                    // Isolated cell with no neighbors
                    Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
                      set_sail(updated_graph, rest_itinerary)

                    // Only left neighbor
                    Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions([left_path], new_distance),
                      )

                    // Only down neighbor
                    Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions([down_path], new_distance),
                      )

                    // Only right neighbor
                    Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions([right_path], new_distance),
                      )

                    // Only top neighbor
                    Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions([top_path], new_distance),
                      )

                    // Down and left neighbors
                    Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [down_path, left_path],
                            new_distance,
                          ),
                      )

                    // Right and left neighbors
                    Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [right_path, left_path],
                            new_distance,
                          ),
                      )

                    // Right, down, and left neighbors
                    Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [right_path, down_path, left_path],
                            new_distance,
                          ),
                      )

                    // Right and down neighbors
                    Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [right_path, down_path],
                            new_distance,
                          ),
                      )

                    // Top and left neighbors
                    Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions([top_path, left_path], new_distance),
                      )

                    // Top, down, and left neighbors
                    Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [top_path, down_path, left_path],
                            new_distance,
                          ),
                      )

                    // Top and down neighbors
                    Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions([top_path, down_path], new_distance),
                      )

                    // Top and right neighbors
                    Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [top_path, right_path],
                            new_distance,
                          ),
                      )

                    // Top, right, and left neighbors
                    Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [top_path, right_path, left_path],
                            new_distance,
                          ),
                      )

                    // Top, right, and down neighbors
                    Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [top_path, right_path, down_path],
                            new_distance,
                          ),
                      )

                    // All four neighbors
                    Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
                      set_sail(
                        updated_graph,
                        rest_itinerary
                          |> add_directions(
                            [top_path, right_path, down_path, left_path],
                            new_distance,
                          ),
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

/// Main entry point: finds shortest path from top-left (0,0) to treasure.
/// Handles edge cases: starting on hazard (-1), starting on treasure (0).
/// Returns distance as integer, or -1 if unreachable.
fn search_for_el_dorado(grid: Grid) {
  // Extract content of starting position (0, 0)
  let start =
    grid
    |> list.first
    |> result.unwrap(or: [])
    |> list.first
    |> result.unwrap(or: Hazard)

  case start {
    // Starting position is blocked - impossible to begin journey
    Hazard -> -1
    // Starting position is the treasure - already at goal
    Treasure -> 0
    // Valid start - build graph and perform BFS
    Water ->
      case plot_course(grid) |> set_sail([#(#(0, 0), 0)]) {
        Ok(distance) -> distance

        Error(Nil) -> -1
      }
  }
}

pub fn run() {
  // Test 1: Basic path with obstacles - Expected: 5
  let grid1 = [
    [Water, Water, Water, Water],
    [Hazard, Water, Hazard, Water],
    [Water, Water, Water, Water],
    [Treasure, Hazard, Hazard, Water],
  ]
  io.println("\n=== Test 1: Basic path with obstacles ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid1)))

  // Test 2: Straight horizontal path - Expected: 3
  let grid2 = [[Water, Water, Water, Treasure]]
  io.println("\n=== Test 2: Straight horizontal path ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid2)))

  // Test 3: Straight vertical path - Expected: 3
  let grid3 = [[Water], [Water], [Water], [Treasure]]
  io.println("\n=== Test 3: Straight vertical path ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid3)))

  // Test 4: Treasure in top-right corner - Expected: 3
  let grid4 = [
    [Water, Water, Water, Treasure],
    [Water, Hazard, Hazard, Water],
    [Water, Water, Water, Water],
    [Water, Hazard, Water, Water],
  ]
  io.println("\n=== Test 4: Treasure in top-right corner ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid4)))

  // Test 5: Treasure in bottom-right corner - Expected: 6
  let grid5 = [
    [Water, Water, Water, Water],
    [Water, Hazard, Hazard, Water],
    [Water, Water, Water, Water],
    [Water, Hazard, Water, Treasure],
  ]
  io.println("\n=== Test 5: Treasure in bottom-right corner ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid5)))

  // Test 6: Completely blocked - Expected: -1 (unreachable)
  let grid6 = [
    [Water, Water, Hazard, Hazard],
    [Water, Water, Hazard, Hazard],
    [Hazard, Hazard, Hazard, Water],
    [Hazard, Hazard, Water, Treasure],
  ]
  io.println("\n=== Test 6: Unreachable treasure ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid6)))

  // Test 7: Maze with multiple turns - Expected: 6
  let grid7 = [
    [Water, Hazard, Water, Water],
    [Water, Hazard, Water, Hazard],
    [Water, Water, Water, Hazard],
    [Hazard, Hazard, Water, Treasure],
  ]
  io.println("\n=== Test 7: Maze with multiple turns ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid7)))

  // Test 8: Treasure at start - Expected: 0
  let grid8 = [[Treasure]]
  io.println("\n=== Test 8: Treasure at starting position ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid8)))

  // Test 9: Large open ocean - Expected: 7
  let grid9 = [
    [Water, Water, Water, Water, Water],
    [Water, Water, Water, Water, Water],
    [Water, Water, Water, Water, Water],
    [Water, Water, Water, Water, Treasure],
  ]
  io.println("\n=== Test 9: Large open area ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid9)))

  // Test 10: Narrow corridor - Expected: 6
  let grid10 = [
    [Water, Hazard, Hazard],
    [Water, Hazard, Hazard],
    [Water, Hazard, Hazard],
    [Water, Water, Water],
    [Hazard, Hazard, Treasure],
  ]
  io.println("\n=== Test 10: Narrow corridor ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid10)))

  // Test 11: Spiral pattern - Expected: 11
  let grid11 = [
    [Water, Water, Water, Water, Water],
    [Hazard, Hazard, Hazard, Hazard, Water],
    [Water, Water, Water, Hazard, Water],
    [Water, Hazard, Water, Hazard, Water],
    [Water, Treasure, Water, Water, Water],
  ]
  io.println("\n=== Test 11: Spiral pattern ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid11)))

  // Test 12: Multiple disconnected islands - Expected: -1
  let grid12 = [
    [Water, Water, Hazard, Water, Water],
    [Water, Water, Hazard, Water, Water],
    [Hazard, Hazard, Hazard, Hazard, Hazard],
    [Water, Water, Hazard, Treasure, Water],
    [Water, Water, Hazard, Water, Water],
  ]
  io.println("\n=== Test 12: Disconnected treasure island ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid12)))

  // Test 13: Almost all hazards - Expected: -1
  let grid13 = [
    [Water, Hazard, Hazard],
    [Hazard, Hazard, Hazard],
    [Hazard, Hazard, Treasure],
  ]
  io.println("\n=== Test 13: Almost all hazards ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid13)))

  // Test 14: Diagonal barrier - Expected: 6
  let grid14 = [
    [Water, Water, Water, Water],
    [Water, Hazard, Water, Water],
    [Water, Water, Hazard, Water],
    [Water, Water, Water, Treasure],
  ]
  io.println("\n=== Test 14: Diagonal barrier ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid14)))

  // Test 15: Adjacent treasure - Expected: 1
  let grid15 = [[Water, Treasure]]
  io.println("\n=== Test 15: Adjacent treasure ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid15)))

  // Test 16: Start on hazard - Expected: -1
  let grid16 = [
    [Hazard, Water, Water],
    [Water, Water, Water],
    [Water, Water, Treasure],
  ]
  io.println("\n=== Test 16: Starting on hazard ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid16)))

  // Test 17: Complex zigzag path - Expected: 10
  let grid17 = [
    [Water, Water, Hazard, Hazard, Hazard],
    [Hazard, Water, Hazard, Water, Water],
    [Water, Water, Hazard, Water, Hazard],
    [Water, Hazard, Hazard, Water, Hazard],
    [Water, Water, Water, Water, Treasure],
  ]
  io.println("\n=== Test 17: Complex zigzag path ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid17)))

  // Test 18: Single row with hazard in middle - Expected: -1
  let grid18 = [[Water, Water, Hazard, Water, Treasure]]
  io.println("\n=== Test 18: Blocked single row ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid18)))

  // Test 19: U-shaped path - Expected: 6
  let grid19 = [
    [Water, Water, Water],
    [Water, Hazard, Water],
    [Water, Hazard, Water],
    [Water, Hazard, Water],
    [Water, Water, Treasure],
  ]
  io.println("\n=== Test 19: U-shaped detour ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid19)))

  // Test 20: Large grid with optimal path - Expected: 11
  let grid20 = [
    [Water, Water, Water, Water, Water, Water],
    [Water, Hazard, Hazard, Hazard, Hazard, Water],
    [Water, Water, Water, Water, Hazard, Water],
    [Hazard, Hazard, Hazard, Water, Hazard, Water],
    [Water, Water, Water, Water, Hazard, Water],
    [Water, Hazard, Hazard, Hazard, Hazard, Water],
    [Water, Water, Water, Water, Water, Treasure],
  ]
  io.println("\n=== Test 20: Large complex maze ===")
  io.println("Result: " <> string.inspect(search_for_el_dorado(grid20)))
}
