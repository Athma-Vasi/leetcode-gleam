import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// LeetCode Problem 994: Rotting Oranges
/// 
/// Problem: Given a grid where:
/// - 0 represents an empty cell
/// - 1 represents a fresh orange  
/// - 2 represents a rotten orange
/// 
/// Every minute, any fresh orange adjacent (4-directionally) to a rotten orange becomes rotten.
/// Return the minimum number of minutes until no cell has a fresh orange.
/// If impossible, return -1.
/// 
/// Approach: Multi-source BFS (Breadth-First Search) from all initially rotten oranges
/// Time Complexity: O(m * n) where m = rows, n = columns
/// Space Complexity: O(m * n) for the adjacency list and queue
/// Represents the state of a cell in the grid
pub type CellContent {
  Empty
  // Empty cell (0 in original problem)
  Fresh
  // Fresh orange (1 in original problem)
  Discard
  // Rotten orange (2 in original problem)
}

/// 2D grid representation as list of lists
type Grid =
  List(List(CellContent))

/// Cell position as (row, column) tuple
type CellCoordinate =
  #(Int, Int)

/// Result type for path to adjacent cell (top neighbor)
type TopPathResult =
  Result(CellCoordinate, Nil)

/// Result type for path to adjacent cell (right neighbor)
type RightPathResult =
  TopPathResult

/// Result type for path to adjacent cell (down neighbor)
type DownPathResult =
  RightPathResult

/// Result type for path to adjacent cell (left neighbor)
type LeftPathResult =
  DownPathResult

/// Result type for cell content (Ok = valid cell, Error = visited/invalid)
type CellContentResult =
  Result(CellContent, Nil)

/// Graph representation using adjacency list
/// Maps each cell coordinate to a tuple containing:
/// - Cell content
/// - References to top, right, down, and left neighbors
/// Space Complexity: O(m * n) where m = rows, n = columns
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

/// Time elapsed in minutes (used in BFS traversal)
type TimeElapsed =
  Int

/// BFS queue storing cells to visit along with elapsed time
/// Each element is (coordinate, minutes_elapsed)
type ItineraryQueue =
  List(#(CellCoordinate, TimeElapsed))

/// Temporary table tracking previous row during graph construction
/// Used to establish vertical connections between cells
type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

/// Updates the current cell's top (upward) neighbor reference in the graph
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - curr_cell_coordinate: Position of current cell
/// - curr_cell_content: Content of current cell (Empty/Fresh/Discard)
/// - top_cell_coordinate: Position of cell above current cell
/// 
/// Time Complexity: O(1) - Dictionary upsert operation
/// Space Complexity: O(1) - Creates new tuple entry
fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  top_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell - initialize all paths
      None -> #(
        Ok(curr_cell_content),
        Ok(top_cell_coordinate),
        Error(Nil),
        Error(Nil),
        Error(Nil),
      )

      // Cell exists - preserve other paths, update only top path
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

/// Updates the current cell's left neighbor reference in the graph
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - curr_cell_coordinate: Position of current cell
/// - curr_cell_content: Content of current cell
/// - left_cell_coordinate: Position of cell to the left of current cell
/// 
/// Time Complexity: O(1) - Dictionary upsert operation
/// Space Complexity: O(1) - Creates new tuple entry
fn update_current_cells_left_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  left_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell - initialize with left path only
      None -> #(
        Ok(curr_cell_content),
        Error(Nil),
        Error(Nil),
        Error(Nil),
        Ok(left_cell_coordinate),
      )

      // Cell exists - preserve other paths, update only left path
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

/// Updates the left cell's right neighbor reference to point to current cell
/// Establishes bidirectional connection between horizontally adjacent cells
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - left_cell_coordinate: Position of left cell
/// - left_cell_content: Content of left cell
/// - curr_cell_coordinate: Position of current cell (right neighbor of left cell)
/// 
/// Time Complexity: O(1) - Dictionary upsert operation
/// Space Complexity: O(1) - Creates new tuple entry
fn update_left_cells_right_path(
  graph,
  left_cell_coordinate,
  left_cell_content,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Initialize left cell with right path pointing to current cell
      None -> #(
        Ok(left_cell_content),
        Error(Nil),
        Ok(curr_cell_coordinate),
        Error(Nil),
        Error(Nil),
      )

      // Update existing left cell's right path
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

/// Updates the top cell's down neighbor reference to point to current cell
/// Establishes bidirectional connection between vertically adjacent cells
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - top_cell_coordinate: Position of top cell
/// - top_cell_content: Content of top cell
/// - curr_cell_coordinate: Position of current cell (below top cell)
/// 
/// Time Complexity: O(1) - Dictionary upsert operation
/// Space Complexity: O(1) - Creates new tuple entry
fn update_top_cells_down_path(
  graph,
  top_cell_coordinate,
  top_cell_content,
  curr_cell_coordinate,
) -> AdjacencyList {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Initialize top cell with down path pointing to current cell
      None -> #(
        Ok(top_cell_content),
        Error(Nil),
        Error(Nil),
        Ok(curr_cell_coordinate),
        Error(Nil),
      )

      // Update existing top cell's down path
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

/// Establishes connections between current cell and both its left and top neighbors
/// Creates bidirectional edges in the adjacency graph for 4-directional connectivity
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - left_cell_coordinate: Position of left neighbor
/// - left_cell_content: Content of left neighbor
/// - top_cell_coordinate: Position of top neighbor
/// - top_cell_content: Content of top neighbor
/// - curr_cell_coordinate: Position of current cell
/// - curr_cell_content: Content of current cell
/// 
/// Time Complexity: O(1) - Four dictionary upsert operations
/// Space Complexity: O(1) - Updates graph entries
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

/// Establishes bidirectional connection between current cell and its left neighbor
/// Used when there's no top neighbor (first row or top is empty)
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - left_cell_coordinate: Position of left neighbor
/// - left_cell_content: Content of left neighbor
/// - curr_cell_coordinate: Position of current cell
/// - curr_cell_content: Content of current cell
/// 
/// Time Complexity: O(1) - Two dictionary upsert operations
/// Space Complexity: O(1) - Updates graph entries
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

/// Establishes bidirectional connection between current cell and its top neighbor
/// Used when there's no left neighbor (first column or left is empty)
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - top_cell_coordinate: Position of top neighbor
/// - top_cell_content: Content of top neighbor
/// - curr_cell_coordinate: Position of current cell
/// - curr_cell_content: Content of current cell
/// 
/// Time Complexity: O(1) - Two dictionary upsert operations
/// Space Complexity: O(1) - Updates graph entries
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

/// Initializes an isolated cell with no neighbors (island/component start)
/// All path results are Error(Nil) indicating no connections yet
/// 
/// Parameters:
/// - graph: The adjacency list being constructed
/// - curr_cell_coordinate: Position of the isolated cell
/// 
/// Time Complexity: O(1) - Single dictionary insert
/// Space Complexity: O(1) - Adds one graph entry
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

/// Constructs an adjacency list representation of the grid
/// Processes grid left-to-right, top-to-bottom, establishing connections between:
/// - Fresh oranges and their fresh/rotten neighbors
/// - Rotten oranges and their fresh neighbors
/// Empty cells are skipped (no connections)
/// 
/// Algorithm: Single-pass grid traversal with state tracking
/// - Maintains previous row in memory to establish vertical connections
/// - Tracks left cell in current row for horizontal connections
/// 
/// Time Complexity: O(m * n) where m = rows, n = columns
///   - Each cell visited once
///   - Each connection established in O(1) time
/// 
/// Space Complexity: O(m * n)
///   - Adjacency list stores all non-empty cells
///   - Previous row table has O(n) entries maximum
/// 
/// Parameters:
/// - grid: 2D list representing the orange grid
/// 
/// Returns: AdjacencyList mapping coordinates to neighbor connections
fn build_graph(grid: Grid) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()

  let #(_prev_row_table, graph) =
    grid
    |> list.index_fold(
      from: #(initial_prev_row_table, initial_graph),
      with: fn(row_acc, row, row_index) {
        let #(prev_row_table, graph) = row_acc

        let initial_left_cell_content = Empty

        let #(_left_cell_content, updated_prev_row_table, updated_graph) =
          row
          |> list.index_fold(
            from: #(initial_left_cell_content, prev_row_table, graph),
            with: fn(column_acc, curr_cell_content, column_index) {
              let #(left_cell_content, prev_row_table, graph) = column_acc

              // Retrieve top neighbor from previous row (Empty if first row)
              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell_content =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: Empty)

              // Current cell coordinates and prev row table update
              let curr_cell_coordinate = #(row_index, column_index)
              let updated_prev_row_table =
                prev_row_table
                |> dict.insert(
                  for: curr_cell_coordinate,
                  insert: curr_cell_content,
                )
                |> dict.delete(top_cell_coordinate)
              let left_cell_coordinate = #(row_index, column_index - 1)

              // Pattern match on (left, top, current) to determine connection strategy
              // Only connect cells that can propagate rot:
              // - Fresh to Fresh/Rotten
              // - Rotten to Fresh
              // Empty cells are isolated (no connections)
              case left_cell_content, top_cell_content, curr_cell_content {
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

  io.println("\n")
  graph
  |> dict.each(fn(key, value) {
    io.println("\n")
    io.println("Key: " <> string.inspect(key))
    io.println("Value: " <> string.inspect(value))
  })

  graph
}

/// Adds newly reachable cells to the BFS queue with updated time
/// Each neighbor becomes rotten one minute after the current cell
/// 
/// Parameters:
/// - rest_itinerary: Existing BFS queue
/// - paths: List of neighbor coordinates to add
/// - updated_minutes: Time when these neighbors become rotten
/// 
/// Time Complexity: O(k) where k = number of paths (at most 4)
/// Space Complexity: O(k) for queue growth
fn add_directions(
  rest_itinerary: ItineraryQueue,
  paths: List(CellCoordinate),
  updated_minutes: Int,
) {
  paths
  |> list.fold(from: rest_itinerary, with: fn(queue, path) {
    queue |> list.append([#(path, updated_minutes)])
  })
}

/// Performs BFS traversal from a single rotten orange source
/// Simulates rot spreading minute-by-minute through connected fresh oranges
/// 
/// Algorithm: Breadth-First Search (BFS)
/// - Queue contains (coordinate, time) pairs
/// - For each cell, visit all 4-directional neighbors
/// - Mark visited cells by removing from graph
/// - Track maximum time reached (farthest distance)
/// 
/// Parameters:
/// - graph: Adjacency list (modified destructively as cells visited)
/// - itinerary_queue: BFS queue with (coordinate, elapsed_time) pairs
/// - minutes_for_full_spoilage: Current maximum time recorded
/// 
/// Returns: Tuple of (max_minutes, updated_graph)
/// 
/// Time Complexity: O(V + E) where V = cells, E = edges
///   - Each cell visited at most once (removed after visit)
///   - Each edge traversed at most once
///   - In grid: V = m*n, E ≤ 4*m*n, so O(m*n)
/// 
/// Space Complexity: O(m*n) for the queue in worst case (all cells enqueued)
fn calculate_minutes_to_spoilage_for_this_section(
  graph: AdjacencyList,
  itinerary_queue: ItineraryQueue,
  minutes_for_full_spoilage: Int,
) {
  case itinerary_queue {
    // Base case: queue empty, return maximum time reached
    [] -> #(minutes_for_full_spoilage, graph)

    // Process next cell in BFS queue
    [first, ..rest_itinerary] -> {
      let #(cell_coordinate, minutes_for_full_spoilage) = first

      case graph |> dict.get(cell_coordinate) {
        // Cell already visited or doesn't exist - skip
        Error(Nil) ->
          calculate_minutes_to_spoilage_for_this_section(
            graph,
            rest_itinerary,
            minutes_for_full_spoilage,
          )

        // Cell found - process it and enqueue neighbors
        Ok(path_results) -> {
          let #(
            _cell_content_result,
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result,
          ) = path_results
          // Mark as visited by removing from graph
          let updated_graph = graph |> dict.delete(cell_coordinate)
          // Neighbors become rotten one minute later
          let updated_minutes = minutes_for_full_spoilage + 1

          // Pattern match all possible neighbor combinations (16 cases)
          // Each valid neighbor (Ok) gets added to queue with updated time
          case
            top_path_result,
            right_path_result,
            down_path_result,
            left_path_result
          {
            // No neighbors - isolated cell or all neighbors already visited
            Error(Nil), Error(Nil), Error(Nil), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary,
                updated_minutes,
              )

            Error(Nil), Error(Nil), Error(Nil), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([left_path], updated_minutes),
                updated_minutes,
              )

            Error(Nil), Error(Nil), Ok(down_path), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([down_path], updated_minutes),
                updated_minutes,
              )

            Error(Nil), Ok(right_path), Error(Nil), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([right_path], updated_minutes),
                updated_minutes,
              )

            Ok(top_path), Error(Nil), Error(Nil), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([top_path], updated_minutes),
                updated_minutes,
              )

            Error(Nil), Error(Nil), Ok(down_path), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([down_path, left_path], updated_minutes),
                updated_minutes,
              )

            Error(Nil), Ok(right_path), Error(Nil), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([right_path, left_path], updated_minutes),
                updated_minutes,
              )

            Error(Nil), Ok(right_path), Ok(down_path), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions(
                    [right_path, down_path, left_path],
                    updated_minutes,
                  ),
                updated_minutes,
              )

            Error(Nil), Ok(right_path), Ok(down_path), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([right_path, down_path], updated_minutes),
                updated_minutes,
              )

            Ok(top_path), Error(Nil), Error(Nil), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([top_path, left_path], updated_minutes),
                updated_minutes,
              )

            Ok(top_path), Error(Nil), Ok(down_path), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions(
                    [top_path, down_path, left_path],
                    updated_minutes,
                  ),
                updated_minutes,
              )

            Ok(top_path), Error(Nil), Ok(down_path), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([top_path, down_path], updated_minutes),
                updated_minutes,
              )

            Ok(top_path), Ok(right_path), Error(Nil), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions([top_path, right_path], updated_minutes),
                updated_minutes,
              )

            Ok(top_path), Ok(right_path), Error(Nil), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions(
                    [top_path, right_path, left_path],
                    updated_minutes,
                  ),
                updated_minutes,
              )

            Ok(top_path), Ok(right_path), Ok(down_path), Error(Nil) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions(
                    [top_path, right_path, down_path],
                    updated_minutes,
                  ),
                updated_minutes,
              )

            Ok(top_path), Ok(right_path), Ok(down_path), Ok(left_path) ->
              calculate_minutes_to_spoilage_for_this_section(
                updated_graph,
                rest_itinerary
                  |> add_directions(
                    [top_path, right_path, down_path, left_path],
                    updated_minutes,
                  ),
                updated_minutes,
              )
          }
        }
      }
    }
  }
}

/// Calculates total time for all fresh oranges to become rotten
/// Performs multi-source BFS starting from each initially rotten orange
/// 
/// Algorithm:
/// 1. Iterate through grid to find all initially rotten oranges
/// 2. For each rotten orange, run BFS to find maximum distance to any fresh orange
/// 3. Return the maximum time across all BFS traversals
/// 
/// Parameters:
/// - graph: Adjacency list of grid connections
/// - grid: Original grid (to locate initial rotten oranges)
/// 
/// Returns: Maximum minutes elapsed, or -1 if impossible
/// 
/// Time Complexity: O(m * n) overall
///   - Grid iteration: O(m * n)
///   - Each cell processed once across all BFS calls
///   - Multiple BFS calls, but each cell visited at most once total
/// 
/// Space Complexity: O(m * n) for graph and BFS queue
fn calculate_loss_minutes(graph: AdjacencyList, grid: Grid) {
  // Start with -1; if no rotten oranges exist, stays -1
  let initial_max_elapsed_minute = -1

  let #(max_elapsed_minute, _graph) =
    grid
    |> list.index_fold(
      from: #(initial_max_elapsed_minute, graph),
      with: fn(row_acc, row, row_index) {
        let #(max_elapsed_minute, graph) = row_acc

        row
        |> list.index_fold(
          from: #(max_elapsed_minute, graph),
          with: fn(column_acc, _cell, column_index) {
            let #(max_elapsed_minute, graph) = column_acc
            let coordinate = #(row_index, column_index)

            case graph |> dict.get(coordinate) {
              Ok(tuple) -> {
                let #(
                  cell_content_result,
                  _top_path,
                  _right_path,
                  _down_path,
                  _left_path,
                ) = tuple

                case cell_content_result {
                  // Fresh/Empty cells are not sources - skip
                  Ok(Fresh) | Ok(Empty) | Error(Nil) -> #(
                    max_elapsed_minute,
                    graph,
                  )

                  // Found a rotten orange - run BFS from this source
                  Ok(Discard) -> {
                    // Run BFS from this rotten orange (starting at minute 0)
                    let #(sections_elapsed_minute, updated_graph) =
                      calculate_minutes_to_spoilage_for_this_section(
                        graph,
                        [#(coordinate, 0)],
                        0,
                      )

                    // Track maximum time across all connected components
                    case max_elapsed_minute > sections_elapsed_minute {
                      True -> #(max_elapsed_minute, updated_graph)
                      False -> #(sections_elapsed_minute, updated_graph)
                    }
                  }
                }
              }

              Error(Nil) -> #(max_elapsed_minute, graph)
            }
          },
        )
      },
    )

  max_elapsed_minute
}

/// Main solver function - combines graph building and BFS traversal
/// 
/// Parameters:
/// - grid: 2D grid with Empty/Fresh/Discard cells
/// 
/// Returns: Minimum minutes for all fresh oranges to rot, or -1 if impossible
/// 
/// Overall Time Complexity: O(m * n)
/// Overall Space Complexity: O(m * n)
fn t(grid: Grid) {
  build_graph(grid) |> calculate_loss_minutes(grid)
}

/// Test runner with example grid
/// 
/// Example grid:
/// ```
/// [Fresh, Fresh, Fresh, Fresh, Discard]
/// [Fresh, Fresh, Empty, Fresh, Fresh]
/// [Fresh, Fresh, Fresh, Empty, Fresh]
/// ```
/// 
/// Expected output: 7
/// - Rotten orange at (0,4) spreads to all reachable fresh oranges
/// - Farthest orange at (2,1) takes 7 minutes to reach
pub fn run() {
  let grid1: Grid = [
    [Fresh, Fresh, Fresh, Fresh, Discard],
    [Fresh, Fresh, Empty, Fresh, Fresh],
    [Fresh, Fresh, Fresh, Empty, Fresh],
  ]
  io.println("grid1: " <> string.inspect(t(grid1)))
}
