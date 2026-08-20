import gleam/dict
import gleam/list
import gleam/option

type CellContent {
  Empty
  Obstacle
}

type Grid =
  List(List(CellContent))

type CellCoordinate =
  #(Int, Int)

type TopPathResult =
  Result(CellCoordinate, Nil)

type RightPathResult =
  TopPathResult

type BottomPathResult =
  TopPathResult

type LeftPathResult =
  TopPathResult

type CellContentResult =
  Result(CellContent, Nil)

type AdjacencyMap =
  dict.Dict(
    CellCoordinate,
    #(
      CellContentResult,
      TopPathResult,
      RightPathResult,
      BottomPathResult,
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
      // First time seeing this cell - initialize all paths
      option.None -> #(
        Ok(curr_cell_content),
        Ok(top_cell_coordinate),
        Error(Nil),
        Error(Nil),
        Error(Nil),
      )

      // Cell exists - preserve other paths, update only top path
      option.Some(path_results) -> {
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
      // First time seeing this cell - initialize with left path only
      option.None -> #(
        Ok(curr_cell_content),
        Error(Nil),
        Error(Nil),
        Error(Nil),
        Ok(left_cell_coordinate),
      )

      // Cell exists - preserve other paths, update only left path
      option.Some(path_results) -> {
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
) -> AdjacencyMap {
  graph
  |> dict.upsert(update: left_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Initialize left cell with right path pointing to current cell
      option.None -> #(
        Ok(left_cell_content),
        Error(Nil),
        Ok(curr_cell_coordinate),
        Error(Nil),
        Error(Nil),
      )

      // Update existing left cell's right path
      option.Some(path_results) -> {
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
) -> AdjacencyMap {
  graph
  |> dict.upsert(update: top_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // Initialize top cell with down path pointing to current cell
      option.None -> #(
        Ok(top_cell_content),
        Error(Nil),
        Error(Nil),
        Ok(curr_cell_coordinate),
        Error(Nil),
      )

      // Update existing top cell's down path
      option.Some(path_results) -> {
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

fn build_graph(grid: Grid) -> AdjacencyMap {
  let initial_graph: AdjacencyMap = dict.new()
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_acc = #(initial_graph, initial_prev_row_table)

  let #(graph, _prev_row_table) =
    grid
    |> list.index_fold(from: initial_acc, with: fn(acc, row, row_index) {
      row
      |> list.index_fold(
        from: acc,
        with: fn(column_acc, curr_cell_content, column_index) {
          let #(graph, prev_row_table) = column_acc
        },
      )
    })

  graph
}
