import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue as queue

type From =
  String

type To =
  String

type Ancestor =
  String

type Weight =
  Int

type BiDirectionalEdge =
  #(From, To, Weight)

type BiDirectionalEdges =
  List(BiDirectionalEdge)

type AdjacencyList =
  dict.Dict(From, List(#(To, Weight)))

type PriorityQueue =
  queue.Queue(#(From, Weight, Ancestor))

type Stack =
  List(#(From, Weight, Ancestor))

fn build_graph(from bi_directional_edges: BiDirectionalEdges) -> AdjacencyList {
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

fn initialize_unexplored_nodes(
  bi_directional_edges: BiDirectionalEdges,
) -> PriorityQueue {
  let first =
    bi_directional_edges
    |> list.first
    |> result.unwrap(or: #("", "", -1))
  let #(first_from, _first_to, _first_weight) = first
  let initial_set = set.new() |> set.insert(#(first_from, 0, ""))
  let initial_priority_queue =
    queue.new(fn(n1, n2) {
      let #(from1, _weight1, _ancestor1) = n1
      let #(from2, _weight2, _ancestor2) = n2
      from1 |> string.compare(from2)
    })

  bi_directional_edges
  |> list.fold(from: initial_set, with: fn(set_acc, bi_directional_edge) {
    let #(from, to, _weight) = bi_directional_edge
    set_acc |> set.insert(#(from, -1, "")) |> set.insert(#(to, -1, ""))
  })
  |> set.fold(from: initial_priority_queue, with: fn(priority_queue, node) {
    priority_queue |> queue.push(node)
  })
}

fn djikstra_traversal(
  explored: Stack,
  unexplored: PriorityQueue,
  graph: AdjacencyList,
) {
  case unexplored |> queue.is_empty {
    True -> {
      explored
    }
    False -> {
      case unexplored |> queue.pop {
        Error(Nil) -> {
          todo
        }
        Ok(tuple) -> {
          let #(minimum, unexplored_popped) = tuple
          let #(from, weight, ancestor) = minimum

          case graph |> dict.get(from) {
            Error(Nil) -> {
              todo
            }
            Ok(edges) -> {
              todo
            }
          }
        }
      }
    }
  }
}

fn t(
  _n: Int,
  bi_directional_edges: BiDirectionalEdges,
  _distance_threshold: Int,
) {
  let unexplored = initialize_unexplored_nodes(bi_directional_edges)
  io.println("\n")
  io.println("unexplored: " <> string.inspect(unexplored))

  build_graph(from: bi_directional_edges)
}

pub fn run() {
  let n1 = 4
  let edges1 = [#("a", "b", 3), #("b", "c", 1), #("b", "d", 4), #("c", "d", 1)]
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
