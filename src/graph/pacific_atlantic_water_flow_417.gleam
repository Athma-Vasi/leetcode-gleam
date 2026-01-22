import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string

pub type CellContent {
  Pacific
  Atlantic
  Land(value: Int)
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

type TimeElapsed =
  Int

type ItineraryQueue =
  List(CellCoordinate)

type PrevRowTable =
  dict.Dict(CellCoordinate, CellContent)

type PacificShoreline =
  set.Set(CellCoordinate)

type AtlanticShoreline =
  PacificShoreline

fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  curr_cell_content,
  top_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      None -> #(
        Ok(curr_cell_content),
        Ok(top_cell_coordinate),
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
      None -> #(
        Ok(curr_cell_content),
        Error(Nil),
        Error(Nil),
        Error(Nil),
        Ok(left_cell_coordinate),
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
      None -> #(
        Ok(left_cell_content),
        Error(Nil),
        Ok(curr_cell_coordinate),
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
      None -> #(
        Ok(top_cell_content),
        Error(Nil),
        Error(Nil),
        Ok(curr_cell_coordinate),
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

              let top_cell_coordinate = #(row_index - 1, column_index)
              let top_cell_content =
                prev_row_table
                |> dict.get(top_cell_coordinate)
                |> result.unwrap(or: Pacific)

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
                // origin Pacific, 0th row, 0th column
                Pacific, Pacific, Pacific -> {
                  #(curr_cell_content, updated_prev_row_table, graph)
                }
                // bottom-left point
                Atlantic, Pacific, Atlantic -> {
                  #(curr_cell_content, updated_prev_row_table, graph)
                }
                // 1st to 2nd-last column, last row atlantic
                Atlantic, top_cell_content, Atlantic -> {
                  #(
                    curr_cell_content,
                    updated_prev_row_table,
                    graph
                      |> update_top_cells_down_path(
                        top_cell_coordinate,
                        top_cell_content,
                        curr_cell_coordinate,
                      ),
                  )
                }
                // bottom-right point
                // Atlantic, Atlantic, Atlantic -> {
                //   #(curr_cell_content, updated_prev_row_table, graph)
                // }
                // 1st row & last column atlantic, and last column atlantic
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
                      ),
                  )
                }

                // origin land
                Pacific, Pacific, curr_cell_content -> {
                  #(
                    curr_cell_content,
                    updated_prev_row_table,
                    graph
                      |> update_current_cells_left_path(
                        curr_cell_coordinate,
                        curr_cell_content,
                        left_cell_coordinate,
                      ),
                  )
                }
                // 1st column land
                Pacific, Land(top_cell_value), Land(curr_cell_value) -> {
                  case top_cell_value <= curr_cell_value {
                    True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                        ),
                    )

                    False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_top_cells_down_path(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                        ),
                    )
                  }
                }

                // 1st row land
                Land(left_cell_value), Pacific, Land(curr_cell_value) -> {
                  case left_cell_value <= curr_cell_value {
                    True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                        ),
                    )

                    False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_cells_right_path(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                        ),
                    )
                  }
                }

                // 2nd to m-1,n-1 land
                Land(left_cell_value),
                  Land(top_cell_value),
                  Land(curr_cell_value)
                -> {
                  case
                    left_cell_value <= curr_cell_value,
                    top_cell_value <= curr_cell_value
                  {
                    True, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                        )
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                        ),
                    )

                    True, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_current_cells_left_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          left_cell_coordinate,
                        )
                        |> update_top_cells_down_path(
                          top_cell_coordinate,
                          top_cell_content,
                          curr_cell_coordinate,
                        ),
                    )

                    False, True -> #(
                      curr_cell_content,
                      updated_prev_row_table,
                      graph
                        |> update_left_cells_right_path(
                          left_cell_coordinate,
                          left_cell_content,
                          curr_cell_coordinate,
                        )
                        |> update_current_cells_top_path(
                          curr_cell_coordinate,
                          curr_cell_content,
                          top_cell_coordinate,
                        ),
                    )

                    False, False -> #(
                      curr_cell_content,
                      updated_prev_row_table,
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
                        ),
                    )
                  }
                }

                // not possible states
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

  io.println("\n")
  graph
  |> dict.each(fn(key, value) {
    io.println("\n")
    io.println("Key: " <> string.inspect(key))
    io.println("Value: " <> string.inspect(value))
  })

  graph
}
