import gleam/dict
import gleam/list
import gleam/option.{type Option}

type AdjacencyList =
  dict.Dict(Int, #(Option(Int), Option(Int)))

fn build_index_table(root: List(Option(Int))) {
  root
  |> list.index_fold(from: dict.new(), with: fn(table, num, index) {
    table |> dict.insert(index, num)
  })
}

fn update_left_descendant(graph, key: Int, value: Int) {
  graph
  |> dict.upsert(update: key, with: fn(descendants_maybe) {
    case descendants_maybe {
      option.None -> #(option.Some(value), option.None)
      option.Some(descendants) -> {
        let #(_left_maybe, right_maybe) = descendants
        #(option.Some(value), right_maybe)
      }
    }
  })
}

fn update_right_descendant(graph, key: Int, value: Int) {
  graph
  |> dict.upsert(update: key, with: fn(descendants_maybe) {
    case descendants_maybe {
      option.None -> #(option.None, option.Some(value))
      option.Some(descendants) -> {
        let #(left_maybe, _right_maybe) = descendants
        #(left_maybe, option.Some(value))
      }
    }
  })
}

fn build_graph(root: List(Option(Int))) {
  let index_table = build_index_table(root)
  root
  |> list.index_fold(from: dict.new(), with: fn(graph, num_maybe, index) {
    let left_index = 2 * index + 1
    let right_index = 2 * index + 2

    case
      index_table |> dict.get(left_index),
      index_table |> dict.get(right_index),
      num_maybe
    {
      Error(Nil), Error(Nil), option.None
      | Error(Nil), Ok(option.None), option.None
      | Error(Nil), Ok(option.Some(_right_descendant)), option.None
      | Ok(option.None), Error(Nil), option.None
      | Ok(option.None), Ok(option.None), option.None
      | Ok(option.None), Ok(option.Some(_right_descendant)), option.None
      | Ok(option.Some(_left_descendant)), Error(Nil), option.None
      | Ok(option.Some(_left_descendant)), Ok(option.None), option.None
      | Ok(option.Some(_left_descendant)),
        Ok(option.Some(_right_descendant)),
        option.None
      | Error(Nil), Error(Nil), option.Some(_num)
      | Error(Nil), Ok(option.None), option.Some(_num)
      | Ok(option.None), Error(Nil), option.Some(_num)
      | Ok(option.None), Ok(option.None), option.Some(_num)
      -> graph

      Error(Nil), Ok(option.Some(right_descendant)), option.Some(num)
      | Ok(option.None), Ok(option.Some(right_descendant)), option.Some(num)
      -> graph |> update_right_descendant(num, right_descendant)

      Ok(option.Some(left_descendant)), Error(Nil), option.Some(num)
      | Ok(option.Some(left_descendant)), Ok(option.None), option.Some(num)
      -> graph |> update_left_descendant(num, left_descendant)

      Ok(option.Some(left_descendant)),
        Ok(option.Some(right_descendant)),
        option.Some(num)
      ->
        graph
        |> update_left_descendant(num, left_descendant)
        |> update_right_descendant(num, right_descendant)
    }
  })
}

pub fn run() {
  let r1 = [option.Some(1), option.None, option.Some(2), option.Some(3)]
  echo build_graph(r1)
}
