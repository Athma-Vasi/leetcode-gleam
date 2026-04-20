import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/string

type Node =
  Int

type Distance =
  Int

type BiDirectionalEdge =
  #(Node, Node, Distance)

type BiDirectionalEdges =
  List(BiDirectionalEdge)

type AdjacencyList =
  dict.Dict(Node, List(#(Node, Distance)))

fn build_graph(from bi_directional_edges: BiDirectionalEdges) -> AdjacencyList {
  bi_directional_edges
  |> list.fold(from: dict.new(), with: fn(graph, bi_directional_edge) {
    let #(from, to, distance) = bi_directional_edge

    graph
    |> dict.upsert(update: from, with: fn(edges_distances_maybe) {
      case edges_distances_maybe {
        option.None -> [#(to, distance)]
        option.Some(edges_distances) -> [#(to, distance), ..edges_distances]
      }
    })
    |> dict.upsert(update: to, with: fn(edges_distances_maybe) {
      case edges_distances_maybe {
        option.None -> [#(from, distance)]
        option.Some(edges_distances) -> [#(from, distance), ..edges_distances]
      }
    })
  })
}

fn build_tables(from bi_directional_edges: BiDirectionalEdges) {
  let distance_table = dict.new()
  let relaxation_table = dict.new()
  let initial_acc = #(distance_table, relaxation_table)

  bi_directional_edges
  |> list.fold(from: initial_acc, with: fn(acc, bi_directional_edge) {
    let #(distance_table, relaxation_table) = acc
    let #(from, to, distance) = bi_directional_edge

    #(
      distance_table |> dict.insert(for: #(from, to), insert: distance),
      relaxation_table |> dict.insert(for: to, insert: Error(Nil)),
    )
  })
}

fn relax_edges(iterations: Int, distance_table, relaxation_table) {
  todo
}

fn t(
  _n: Int,
  bi_directional_edges: BiDirectionalEdges,
  _distance_threshold: Int,
) {
  let #(distance_table, relaxation_table) =
    build_tables(from: bi_directional_edges)
  io.println("\n")
  io.println("distance_table: ")
  distance_table
  |> dict.each(fn(key, value) {
    io.println("\n")
    io.println("key: " <> string.inspect(key))
    io.println("value: " <> string.inspect(value))
  })

  io.println("\n")
  io.println("relaxation_table: ")
  relaxation_table
  |> dict.each(fn(key, value) {
    io.println("\n")
    io.println("key: " <> string.inspect(key))
    io.println("value: " <> string.inspect(value))
  })
}

pub fn run() {
  let n1 = 4
  let edges1 = [#(1, 3, -2), #(3, 4, 2), #(4, 2, -1), #(2, 1, 4), #(2, 3, 3)]
  let dt1 = 4
  // 3
  t(n1, edges1, dt1)
}
