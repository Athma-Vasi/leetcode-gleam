import gleam/dict.{type Dict}
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}

// T(V,E) = O(E)
// S(V,E) = O(V+E)
fn build_graph(edges: List(#(Int, Int))) -> Dict(Int, List(Int)) {
  edges
  |> list.fold(from: dict.new(), with: fn(acc, curr) {
    let source = pair.first(curr)
    let destination = pair.second(curr)
    let source_adjlist =
      acc
      |> dict.get(source)
      |> result.unwrap([])
      |> list.prepend(destination)
    let dest_adjlist =
      acc
      |> dict.get(destination)
      |> result.unwrap([])
      |> list.prepend(source)

    acc
    |> dict.insert(source, source_adjlist)
    |> dict.insert(destination, dest_adjlist)
  })
}

// T(V,E) = O(V+E)
// S(V,E) = O(V)
fn depth_first_search(
  graph: Dict(Int, List(Int)),
  visited: Set(Int),
  source: Int,
  destination: Int,
) -> Bool {
  source == destination
  || {
    let new_visited = visited |> set.insert(source)
    let destinations = graph |> dict.get(source) |> result.unwrap([])

    destinations
    |> list.any(fn(new_source) {
      !set.contains(new_visited, new_source)
      && depth_first_search(graph, new_visited, new_source, destination)
    })
  }
}

pub fn t(
  _n: Int,
  edges: List(#(Int, Int)),
  source: Int,
  destination: Int,
) -> Bool {
  build_graph(edges)
  |> depth_first_search(set.new(), source, destination)
}

pub fn run() {
  let n1 = 3
  let e1 = [#(0, 1), #(1, 2), #(2, 0)]
  let s1 = 0
  let d1 = 2
  // True
  let _t1 = t(n1, e1, s1, d1)

  let n2 = 6
  let e2 = [#(0, 1), #(0, 2), #(3, 5), #(5, 4), #(4, 3)]
  let s2 = 0
  let d2 = 5
  // False
  t(n2, e2, s2, d2)
}
