import gleam/dict
import gleam/list
import gleam/option

type SourceNode =
  Int

type TargetNode =
  Int

type SignalTravelTime =
  Int

type DirectedEdges =
  List(#(SourceNode, TargetNode, SignalTravelTime))

type AdjacencyList =
  dict.Dict(SourceNode, List(#(TargetNode, SignalTravelTime)))

fn build_graph(directed_edges: DirectedEdges) -> AdjacencyList {
  directed_edges
  |> list.fold(from: dict.new(), with: fn(graph, directed_edge) {
    let #(source_node, target_node, signal_travel_time) = directed_edge

    graph
    |> dict.upsert(update: source_node, with: fn(targets_times_maybe) {
      case targets_times_maybe {
        option.None -> [#(target_node, signal_travel_time)]

        option.Some(targets_times) -> [
          #(target_node, signal_travel_time),
          ..targets_times
        ]
      }
    })
  })
}

pub fn run() {
  let times1 = [#(2, 1, 1), #(2, 3, 1), #(3, 4, 1)]
  echo build_graph(times1)
}
