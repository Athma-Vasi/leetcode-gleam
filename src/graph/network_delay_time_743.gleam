import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/result

type SourceNode =
  Int

type TargetNode =
  Int

type SignalTravelTime =
  Int

type DirectedEdges =
  List(#(SourceNode, TargetNode, SignalTravelTime))

type PropagationNodes =
  List(#(TargetNode, SignalTravelTime))

type AdjacencyList =
  dict.Dict(SourceNode, PropagationNodes)

type PropagationTimes =
  dict.Dict(TargetNode, SignalTravelTime)

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

fn update_propagation_times(
  propagation_times,
  target_node,
  updated_propagation_time,
) -> PropagationTimes {
  propagation_times
  |> dict.upsert(update: target_node, with: fn(prev_shortest_time_maybe) {
    case prev_shortest_time_maybe {
      option.None -> updated_propagation_time

      option.Some(prev_shortest_time) ->
        case prev_shortest_time < updated_propagation_time {
          True -> prev_shortest_time
          False -> updated_propagation_time
        }
    }
  })
}

fn explore_network(
  graph: AdjacencyList,
  itinerary_stack: List(#(TargetNode, SignalTravelTime)),
  shortest_signal_travel_table: dict.Dict(TargetNode, SignalTravelTime),
) {
  case itinerary_stack {
    [] ->
      // No more nodes to process; return the accumulated shortest times.
      shortest_signal_travel_table

    [top, ..rest_stack] -> {
      let #(current_node, current_time) = top

      // 1) Record/relax the arrival time for the current node.
      let new_table =
        shortest_signal_travel_table
        |> update_propagation_times(current_node, current_time)

      // 2) Expand neighbours of the current node.
      let next_stack = case dict.get(graph, current_node) {
        Error(Nil) ->
          // No outgoing edges; continue with remaining stack.
          rest_stack

        Ok(neighbours) ->
          neighbours
          |> list.fold(from: rest_stack, with: fn(acc, neighbor) {
            let #(nbr, edge_time) = neighbor
            let new_time = current_time + edge_time

            // Check existing recorded time (if any).
            case dict.get(new_table, nbr) {
              Ok(prev_time) ->
                // Only enqueue if we found a strictly shorter path.
                case prev_time <= new_time {
                  True -> acc
                  False -> [#(nbr, new_time), ..acc]
                }

              Error(Nil) ->
                // First time seeing this node; enqueue it.
                [#(nbr, new_time), ..acc]
            }
          })
      }

      // 4) Continue recursion with the updated table and stack.
      explore_network(graph, next_stack, new_table)
    }
  }
}

fn sort_desc_by_times(propagation_times: PropagationTimes) {
  propagation_times
  |> dict.to_list
  |> list.sort(by: fn(tuple1, tuple2) {
    let #(_target_node1, signal_travel_time1) = tuple1
    let #(_target_node2, signal_travel_time2) = tuple2
    signal_travel_time2 |> int.compare(with: signal_travel_time1)
  })
}

fn t(times: DirectedEdges, n: Int, k: Int) -> Int {
  build_graph(times)
  |> explore_network([#(k, 0)], dict.new())
  |> sort_desc_by_times
  |> list.first
  |> result.unwrap(or: #(-1, -1))
  |> pair.second
}

pub fn run() {
  echo "=== Network Delay Time (743) - Comprehensive Test Suite ==="

  // 1) Basic example (LeetCode sample)
  let times1 = [#(2, 1, 1), #(2, 3, 1), #(3, 4, 1)]
  let n1 = 4
  let k1 = 2
  let got1 = t(times1, n1, k1)
  echo "Test 1: basic chain (k=2)"
  echo "Expected: 2"
  echo "Got: " <> int.to_string(got1)

  // 2) Two nodes, single edge
  let times2 = [#(1, 2, 1)]
  let got2 = t(times2, 2, 1)
  echo "\nTest 2: two nodes, single edge (k=1)"
  echo "Expected: 1"
  echo "Got: " <> int.to_string(got2)

  // 3) Disconnected graph (expect -1)
  let times3 = [#(1, 2, 1)]
  let got3 = t(times3, 3, 1)
  echo "\nTest 3: disconnected graph (k=1)"
  echo "Expected: -1"
  echo "Got: " <> int.to_string(got3)

  // 4) Multiple paths, choose shorter (1->2->3 beats 1->3)
  let times4 = [#(1, 2, 1), #(1, 3, 4), #(2, 3, 1)]
  let got4 = t(times4, 3, 1)
  echo "\nTest 4: multiple paths, prefer shorter (k=1)"
  echo "Expected: 2"
  echo "Got: " <> int.to_string(got4)

  // 5) Simple cycle; should still compute shortest
  let times5 = [#(1, 2, 1), #(2, 1, 1)]
  let got5 = t(times5, 2, 1)
  echo "\nTest 5: simple cycle (k=1)"
  echo "Expected: 1"
  echo "Got: " <> int.to_string(got5)

  // 6) Direct vs longer path; max arrival dominates
  //    Node 2 at 100, node 3 at 50 -> answer 100
  let times6 = [#(1, 2, 100), #(2, 3, 100), #(1, 3, 50)]
  let got6 = t(times6, 3, 1)
  echo "\nTest 6: direct vs via path (k=1)"
  echo "Expected: 100"
  echo "Got: " <> int.to_string(got6)

  // 7) Duplicate edges; use the smaller weight
  let times7 = [#(1, 2, 5), #(1, 2, 2)]
  let got7 = t(times7, 2, 1)
  echo "\nTest 7: duplicate edges (k=1)"
  echo "Expected: 2"
  echo "Got: " <> int.to_string(got7)

  // 8) Single node graph; delay is 0
  let times8: DirectedEdges = []
  let got8 = t(times8, 1, 1)
  echo "\nTest 8: single node (k=1)"
  echo "Expected: 0"
  echo "Got: " <> int.to_string(got8)

  // 9) Start has no outgoing edges in larger graph (expect -1)
  let times9: DirectedEdges = []
  let got9 = t(times9, 3, 2)
  echo "\nTest 9: no outgoing edges from start (k=2)"
  echo "Expected: -1"
  echo "Got: " <> int.to_string(got9)

  // 10) Equal-weight branching converging to a node
  //     1->2 (1), 1->3 (1), 2->4 (1), 3->4 (1) => max arrival 2
  let times10 = [#(1, 2, 1), #(1, 3, 1), #(2, 4, 1), #(3, 4, 1)]
  let got10 = t(times10, 4, 1)
  echo "\nTest 10: equal weights, branching (k=1)"
  echo "Expected: 2"
  echo "Got: " <> int.to_string(got10)

  // 11) Longer chain
  let times11 = [#(1, 2, 1), #(2, 3, 1), #(3, 4, 1), #(4, 5, 1)]
  let got11 = t(times11, 5, 1)
  echo "\nTest 11: longer chain (k=1)"
  echo "Expected: 4"
  echo "Got: " <> int.to_string(got11)

  // 12) Larger weights chain
  let times12 = [#(1, 2, 5), #(2, 3, 10), #(3, 4, 20)]
  let got12 = t(times12, 4, 1)
  echo "\nTest 12: larger weights chain (k=1)"
  echo "Expected: 35"
  echo "Got: " <> int.to_string(got12)

  // 13) Multiple edges, worse weight shouldn’t matter
  let times13 = [#(1, 2, 1), #(1, 2, 10), #(2, 3, 2)]
  let got13 = t(times13, 3, 1)
  echo "\nTest 13: parallel edges with worse weight (k=1)"
  echo "Expected: 3"
  echo "Got: " <> int.to_string(got13)

  // 14) Unreachable node in presence of reachable others (expect -1)
  let times14 = [#(1, 2, 1)]
  let got14 = t(times14, 4, 1)
  echo "\nTest 14: partially reachable graph (k=1)"
  echo "Expected: -1"
  echo "Got: " <> int.to_string(got14)

  echo "\n=== End of Test Suite ==="
}
