import gleam/dict
import gleam/list
import gleam/option

type Grid =
  List(List(String))

type CellCoordinate =
  #(Int, Int)

type TopPathResult =
  Result(CellCoordinate, Nil)

type RightPathResult =
  TopPathResult

type DownPathResult =
  TopPathResult

type LeftPathResult =
  TopPathResult

type AdjacencyList =
  dict.Dict(
    CellCoordinate,
    #(TopPathResult, RightPathResult, DownPathResult, LeftPathResult),
  )

type PrevRowTable =
  dict.Dict(CellCoordinate, String)

fn update_current_cells_top_path(
  graph,
  curr_cell_coordinate,
  top_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only top neighbor
      option.None -> #(
        Ok(top_cell_coordinate),
        Error(Nil),
        Error(Nil),
        Error(Nil),
      )

      // Cell already has other neighbors: update only the top neighbor
      option.Some(path_results) -> {
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

fn update_current_cells_right_path(
  graph,
  curr_cell_coordinate,
  right_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only right neighbor
      option.None -> #(
        Error(Nil),
        Ok(right_cell_coordinate),
        Error(Nil),
        Error(Nil),
      )

      // Cell already has other neighbors: update only the right neighbor
      option.Some(path_results) -> {
        let #(
          top_path_result,
          _right_path_result,
          down_path_result,
          left_path_result,
        ) = path_results

        #(
          top_path_result,
          Ok(right_cell_coordinate),
          down_path_result,
          left_path_result,
        )
      }
    }
  })
}

fn update_current_cells_down_path(
  graph,
  curr_cell_coordinate,
  down_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only down neighbor
      option.None -> #(
        Error(Nil),
        Error(Nil),
        Ok(down_cell_coordinate),
        Error(Nil),
      )

      // Cell already has other neighbors: update only the down neighbor
      option.Some(path_results) -> {
        let #(
          top_path_result,
          right_path_result,
          _down_path_result,
          left_path_result,
        ) = path_results

        #(
          top_path_result,
          right_path_result,
          Ok(down_cell_coordinate),
          left_path_result,
        )
      }
    }
  })
}

fn update_current_cells_left_path(
  graph,
  curr_cell_coordinate,
  left_cell_coordinate,
) {
  graph
  |> dict.upsert(update: curr_cell_coordinate, with: fn(path_results_maybe) {
    case path_results_maybe {
      // First time seeing this cell: initialize with only left neighbor
      option.None -> #(
        Error(Nil),
        Error(Nil),
        Error(Nil),
        Ok(left_cell_coordinate),
      )

      // Cell already has other neighbors: update only the left neighbor
      option.Some(path_results) -> {
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

fn build_graph(grid: Grid) -> AdjacencyList {
  let initial_prev_row_table: PrevRowTable = dict.new()
  let initial_graph: AdjacencyList = dict.new()
}
