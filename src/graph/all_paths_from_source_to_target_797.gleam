import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result

// Input: graph = [[1,2],[3],[3],[]]
// Output: [[0,1,3],[0,2,3]]
// Explanation: There are two paths: 0 -> 1 -> 3 and 0 -> 2 -> 3.

fn build_digraph(graph: List(List(Int))) {
  graph
  |> list.index_fold(from: dict.new(), with: fn(acc, curr, idx) {
    acc |> dict.insert(idx, curr)
  })
}

// T(N,E) = O(N + E), where N is the number of nodes and E is the number of edges.
// S(N) = O(N), where N is the number of nodes.
fn dfs_helper(
  digraph: Dict(Int, List(Int)),
  result: List(List(Int)),
  stack: List(#(Int, List(Int))),
) {
  let n = dict.size(digraph)
  case stack {
    [] -> result
    [top, ..rest] -> {
      let node = pair.first(top)
      let path = pair.second(top)

      case node == n - 1 {
        // If the current node is the target, add the path to the results and continue.
        True -> dfs_helper(digraph, result |> list.prepend(path), rest)
        // Explore the current node's neighbors.
        False -> {
          let neighbours = digraph |> dict.get(node) |> result.unwrap([])
          let new_stack =
            neighbours
            |> list.fold(from: rest, with: fn(acc, neighbour) {
              acc
              |> list.prepend(#(neighbour, [neighbour, ..path]))
            })

          dfs_helper(digraph, result, new_stack)
        }
      }
    }
  }
}

fn depth_first_search(graph: List(List(Int))) {
  build_digraph(graph)
  |> dfs_helper([], [#(0, [0])])
  |> list.fold(from: [], with: fn(acc, paths) {
    acc |> list.prepend(paths |> list.reverse)
  })
}

fn t(graph: List(List(Int))) {
  depth_first_search(graph)
}

pub fn run() {
  let g1 = [[1, 2], [3], [3], []]
  let r1 = t(g1)
  r1
  |> list.each(fn(paths) {
    paths
    |> list.each(fn(path) { io.println("path" <> int.to_string(path)) })
  })
}
