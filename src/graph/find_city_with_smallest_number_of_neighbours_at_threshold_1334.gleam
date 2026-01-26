import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/string

type From =
  Int

type To =
  Int

type Weight =
  Int

type BiDirectionalEdge =
  #(From, To, Weight)

type BiDirectionalEdges =
  List(BiDirectionalEdge)

type AdjacencyList =
  dict.Dict(From, List(#(To, Weight)))

fn build_graph(from bi_directional_edges: BiDirectionalEdges) {
  bi_directional_edges
  |> list.fold(from: dict.new(), with: fn(graph, bi_directional_edge) {
    let #(from, to, weight) = bi_directional_edge

    graph
    |> dict.upsert(update: from, with: fn(edges_weights_maybe) {
      case edges_weights_maybe {
        option.None -> [#(to, weight)]
        option.Some(edges_weights) -> [#(to, weight), ..edges_weights]
      }
    })
    |> dict.upsert(update: to, with: fn(edges_weights_maybe) {
      case edges_weights_maybe {
        option.None -> [#(from, weight)]
        option.Some(edges_weights) -> [#(from, weight), ..edges_weights]
      }
    })
  })
}

fn t(
  _n: Int,
  bi_directional_edges: BiDirectionalEdges,
  _distance_threshold: Int,
) {
  build_graph(from: bi_directional_edges)
}

pub fn run() {
  let n1 = 4
  let edges1 = [#(0, 1, 3), #(1, 2, 1), #(1, 3, 4), #(2, 3, 1)]
  let dt1 = 4
  // 3
  io.println("\n")
  io.println("graph: ")
  t(n1, edges1, dt1)
  |> dict.each(fn(key, value) {
    io.println("\n")
    io.println("key: " <> string.inspect(key))
    io.println("value: " <> string.inspect(value))
  })
}
