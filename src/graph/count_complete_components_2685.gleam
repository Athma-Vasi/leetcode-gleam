import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}

// incorrect

fn build_graph(edges: List(#(Int, Int))) -> Dict(Int, Set(Int)) {
  let graph_seed =
    list.range(0, 5)
    |> list.fold(from: dict.new(), with: fn(acc, curr) {
      acc |> dict.insert(curr, set.new())
    })

  edges
  |> list.fold(from: graph_seed, with: fn(acc, curr) {
    let source = pair.first(curr)
    let destination = pair.second(curr)
    let source_adjlist =
      acc
      |> dict.get(source)
      |> result.unwrap(set.new())
      |> set.insert(destination)
      |> set.insert(source)
    let dest_adjlist =
      acc
      |> dict.get(destination)
      |> result.unwrap(set.new())
      |> set.insert(source)
      |> set.insert(destination)

    acc
    |> dict.insert(source, source_adjlist)
    |> dict.insert(destination, dest_adjlist)
  })
}

fn count_frequency(graph: Dict(Int, Set(Int))) -> Dict(List(Int), Int) {
  graph
  |> dict.fold(from: dict.new(), with: fn(acc, _key, value) {
    let sorted_neighbours = value |> set.to_list |> list.sort(by: int.compare)
    let freq = { acc |> dict.get(sorted_neighbours) |> result.unwrap(0) } + 1

    acc |> dict.insert(sorted_neighbours, freq)
  })
}

fn count_complete_components(freq_table: Dict(List(Int), Int)) -> Int {
  freq_table
  |> dict.fold(from: 0, with: fn(acc, neighbors, freq_count) {
    case list.length(neighbors) == freq_count {
      True -> acc + 1
      False -> acc
    }
  })
}

fn t(_n: Int, edges: List(#(Int, Int))) -> Int {
  build_graph(edges)
  |> count_frequency
  |> count_complete_components
}

pub fn run() -> Nil {
  let n1 = 6
  let e1 = [#(0, 1), #(0, 2), #(1, 2), #(3, 4)]
  t(n1, e1) |> int.to_string |> io.println
  // 3
}
