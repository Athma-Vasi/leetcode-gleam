import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/string

type AdjacencyList =
  dict.Dict(Int, #(Result(Int, Nil), Result(Int, Nil)))

fn build_index_table(
  root: List(Result(Int, Nil)),
) -> dict.Dict(Int, Result(Int, Nil)) {
  root
  |> list.index_fold(from: dict.new(), with: fn(table, num, index) {
    table |> dict.insert(index, num)
  })
}

fn update_left_descendant(graph, key: Int, value_result: Result(Int, Nil)) {
  graph
  |> dict.upsert(update: key, with: fn(descendants_maybe) {
    case descendants_maybe {
      option.None -> #(value_result, Error(Nil))
      option.Some(descendants) -> {
        let #(_left_result, right_result) = descendants
        #(value_result, right_result)
      }
    }
  })
}

fn update_right_descendant(graph, key: Int, value_result: Result(Int, Nil)) {
  graph
  |> dict.upsert(update: key, with: fn(descendants_maybe) {
    case descendants_maybe {
      option.None -> #(Error(Nil), value_result)
      option.Some(descendants) -> {
        let #(left_result, _right_result) = descendants
        #(left_result, value_result)
      }
    }
  })
}

fn initialize_graph(root: List(Result(Int, Nil))) {
  root
  |> list.fold(from: dict.new(), with: fn(graph, num_maybe) {
    case num_maybe {
      Error(Nil) -> graph
      Ok(num) ->
        graph |> dict.insert(for: num, insert: #(Error(Nil), Error(Nil)))
    }
  })
}

fn grab_descendants(
  root: List(Result(Int, Nil)),
  from start_index: Int,
  to end_index: Int,
) {
  let #(descendants, rest_root) =
    root
    |> list.index_fold(from: #([], []), with: fn(acc, num_maybe, curr_index) {
      let #(descendants, rest_root) = acc
      case start_index < 0, start_index <= curr_index, curr_index < end_index {
        True, _, _ -> #([num_maybe], rest_root)
        False, True, True -> #([num_maybe, ..descendants], rest_root)
        False, False, False -> #(descendants, [num_maybe, ..rest_root])
        False, False, True | False, True, False -> acc
      }
    })

  #(list.reverse(descendants), list.reverse(rest_root))
}

fn add_descendants(
  graph: AdjacencyList,
  ancestors: List(Result(Int, Nil)),
  descendants: List(Result(Int, Nil)),
) {
  case ancestors {
    [] -> graph

    [prev_level_ancestor_result, ..rest_ancestors] -> {
      case descendants {
        [] | [_] -> graph

        [left_descendant_result, right_descendant_result, ..rest_descendants] -> {
          case prev_level_ancestor_result {
            Error(Nil) -> graph

            Ok(prev_level_ancestor) ->
              add_descendants(
                graph
                  |> update_left_descendant(
                    prev_level_ancestor,
                    left_descendant_result,
                  )
                  |> update_right_descendant(
                    prev_level_ancestor,
                    right_descendant_result,
                  ),
                rest_ancestors,
                rest_descendants,
              )
          }
        }
      }
    }
  }
}

fn build_graph(
  graph: AdjacencyList,
  root: List(Result(Int, Nil)),
  level: Int,
  height: Int,
  prev_start_index: Int,
  ancestors: List(Result(Int, Nil)),
) {
  case root {
    [] -> graph

    root -> {
      let start_index = prev_start_index * 2 + 1
      let end_index = level * height
      let #(descendants, rest_root) =
        root |> grab_descendants(from: start_index, to: end_index)
      let updated_graph = graph |> add_descendants(ancestors, descendants)
      build_graph(
        updated_graph,
        rest_root,
        level + 1,
        height + 1,
        start_index,
        descendants,
      )
    }
  }
}

pub fn run() {
  let r1 = [Ok(1), Error(Nil), Ok(2), Ok(3)]
  echo initialize_graph(r1) |> build_graph(r1, 0, 1, -1, [])
}
