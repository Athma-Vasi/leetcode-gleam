import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import gleamy/priority_queue as p_queue

type Node =
  Int

type Distance =
  Int

type Ancestor =
  Int

type BiDirectionalEdge =
  #(Node, Node, Distance)

type BiDirectionalEdges =
  List(BiDirectionalEdge)

type AdjacencyList =
  dict.Dict(Node, List(#(Node, Distance)))

type DistanceAncestorTable =
  dict.Dict(Node, #(Distance, Ancestor))

type PriorityQueue =
  p_queue.Queue(#(Node, Distance))

type DistanceTable =
  dict.Dict(#(Node, Node), Distance)

type ExploredStack =
  List(#(Node, Distance, Ancestor))

type AncestorTable =
  dict.Dict(Node, Node)

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

fn build_distance_table(
  bi_directional_edges: BiDirectionalEdges,
) -> DistanceTable {
  bi_directional_edges
  |> list.fold(from: dict.new(), with: fn(table, edge) {
    let #(from, to, distance) = edge

    table
    |> dict.insert(for: #(from, from), insert: 0)
    |> dict.insert(for: #(from, to), insert: distance)
    |> dict.insert(for: #(to, to), insert: 0)
  })
}

fn create_p_queue() {
  p_queue.new(fn(t1, t2) {
    let #(_node1, accum_distance1) = t1
    let #(_node2, accum_distance2) = t2
    accum_distance1 |> int.compare(accum_distance2)
  })
}

fn initialize_priority_queue(
  bi_directional_edges: BiDirectionalEdges,
  start_node: Int,
) -> PriorityQueue {
  bi_directional_edges
  |> list.fold(from: create_p_queue(), with: fn(acc, bi_directional_edge) {
    let #(from, to, _distance) = bi_directional_edge

    case start_node == from, start_node == to {
      True, True | False, False -> acc

      True, False -> acc |> p_queue.push(#(from, 0))

      False, True -> acc |> p_queue.push(#(to, 0))
    }
  })
}

fn update_node_in_queue(
  queue: PriorityQueue,
  node_to_update: Node,
  accum_distance_to_update: Distance,
) {
  queue
  |> p_queue.to_list
  |> list.fold(from: create_p_queue(), with: fn(acc, tuple) {
    let #(curr_node, _curr_accum_distance) = tuple
    case curr_node == node_to_update {
      True -> acc |> p_queue.push(#(curr_node, accum_distance_to_update))
      False -> acc |> p_queue.push(tuple)
    }
  })
}

fn update_node_in_distance_table(
  distance_table: DistanceTable,
  from_to_to: #(Node, Node),
  accum_distance_to_update: Distance,
) {
  distance_table
  |> dict.insert(for: from_to_to, insert: accum_distance_to_update)
}

fn update_node_in_ancestor_table(
  ancestor_table: AncestorTable,
  node_to_update: Node,
  accum_distance_to_update: Distance,
) {
  ancestor_table
  |> dict.insert(for: node_to_update, insert: accum_distance_to_update)
}

fn djikstra(
  graph: AdjacencyList,
  explored_stack: ExploredStack,
  unexplored_queue: PriorityQueue,
  explored_set: set.Set(Node),
  distance_table: DistanceTable,
  ancestor_table: AncestorTable,
) {
  // initialize pq
  // select the value with the smallest accum_distance first
  // grab its edges from graph
  // iterate through edges 
  // if the edge has been visited, ignore
  // if new, accum_distance of the edgeent vertex plus
  // the weight to the adjacent vertex < adjacent vertex's accum_distance
  // if yes, update the adjacent vertex's accum_distance in table

  case explored_stack, p_queue.pop(unexplored_queue) {
    [], Error(Nil) -> {
      explored_stack
    }
    // initial: starting node
    [], Ok(tuple) -> {
      let #(node_and_distance, queue) = tuple
      let #(node, accum_distance) = node_and_distance
      djikstra(
        graph,
        [#(node, accum_distance, node), ..explored_stack],
        queue,
        explored_set |> set.insert(this: node),
        distance_table,
        ancestor_table,
      )
    }
    [_top, ..], Error(Nil) -> {
      explored_stack
    }
    [top, ..rest_stack], Ok(tuple) -> {
      let #(node_and_distance, queue) = tuple
      let #(priority_node, priority_accum_distance) = node_and_distance
      let #(edge_node, edge_accum_distance, edge_parent) = top
      let edges = graph |> dict.get(priority_node) |> result.unwrap(or: [])
      let #(
        updated_explored_stack,
        updated_distance_table,
        updated_ancestor_table,
      ) =
        edges
        |> list.fold(
          from: #(explored_stack, distance_table, ancestor_table),
          with: fn(acc, edge) {
            let #(explored_stack, distance_table, ancestor_table) = acc
            let #(adj_node, weight) = edge

            case
              explored_set |> set.contains(this: priority_node),
              distance_table |> dict.get(#(priority_node, edge_node)),
              ancestor_table |> dict.get(priority_node)
            {
              True, _, _ -> acc
              False, Error(Nil), _ -> acc
              False, _, Error(Nil) -> acc
              False, Ok(distance_from_table), Ok(ancestor_from_table) -> {
                case edge_accum_distance + weight < priority_accum_distance {
                  True -> {
                    let updated_distance_table =
                      update_node_in_distance_table(
                        distance_table,
                        #(priority_node, edge_node),
                        edge_accum_distance + weight,
                      )
                    let updated_ancestor_table =
                      update_node_in_ancestor_table(
                        ancestor_table,
                        edge_node,
                        priority_node,
                      )
                    let updated_explored_stack = [
                      #(priority_node, edge_accum_distance + weight, edge_node),
                      ..explored_stack
                    ]
                    #(
                      updated_explored_stack,
                      updated_distance_table,
                      updated_ancestor_table,
                    )
                  }
                  False -> acc
                }
              }
              // True -> acc
              // False -> {
              //   let #(adj_node, weight) = edge
              //   case edge_accum_distance + weight < priority_accum_distance {
              //     True -> {
              //       todo
              //       // djikstra(
              //       //   graph,
              //       //   [#(priority_node,edge_accum_distance+weight,)]
              //       // )
              //     }
              //     False -> acc
              //   }
              // }
            }
          },
        )

      djikstra(
        graph,
        explored_stack,
        unexplored_queue,
        explored_set,
        distance_table,
        ancestor_table,
      )
    }
  }
}

fn t(
  _n: Int,
  bi_directional_edges: BiDirectionalEdges,
  _distance_threshold: Int,
) {
  let graph = build_graph(from: bi_directional_edges)
  io.println("\n")
  io.println("graph: ")
  graph
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
// fn floyd_warshall_traversal(distance_table: DistanceTable, n: Int) {
//   let #(intermediates, froms, tos) = #(
//     list.range(1, n),
//     list.range(1, n),
//     list.range(1, n),
//   )

//   intermediates
//   |> list.fold(from: distance_table, with: fn(updated_table, intermediate) {
//     froms
//     |> list.fold(from: updated_table, with: fn(updated_table, from) {
//       tos
//       |> list.fold(from: updated_table, with: fn(updated_table, to) {
//         io.println("\n")
//         io.println("#(from,to): " <> string.inspect(#(from, to)))
//         io.println(
//           "#(from,intermediate): " <> string.inspect(#(from, intermediate)),
//         )
//         io.println(
//           "#(intermediate,to): " <> string.inspect(#(intermediate, to)),
//         )

//         case
//           distance_table |> dict.get(#(from, to)),
//           distance_table |> dict.get(#(from, intermediate)),
//           distance_table |> dict.get(#(intermediate, to))
//         {
//           // Error(Nil), Error(Nil), Error(Nil) -> {
//           //   updated_table
//           // }
//           // Error(Nil), Error(Nil), Ok(intermediate_to_to) -> {
//           //   updated_table
//           // }
//           // Error(Nil), Ok(from_to_intermediate), Error(Nil) -> {
//           //   updated_table
//           // }
//           // Ok(from_to_to), Error(Nil), Error(Nil) -> {
//           //   updated_table
//           // }
//           // Ok(from_to_to), Error(Nil), Ok(intermediate_to_to) -> {
//           //   updated_table
//           // }
//           // Ok(from_to_to), Ok(from_to_intermediate), Error(Nil) -> {
//           //   updated_table
//           // }
//           Error(Nil), Ok(from_to_intermediate), Ok(intermediate_to_to) -> {
//             // infinity > { from_to_intermediate + intermediate_to_to }            
//             let updated_table =
//               updated_table
//               |> dict.upsert(update: #(from, to), with: fn(distance_maybe) {
//                 case distance_maybe {
//                   option.None -> from_to_intermediate + intermediate_to_to

//                   option.Some(distance) ->
//                     int.min(distance, from_to_intermediate + intermediate_to_to)
//                 }
//               })

//             io.println("\n")
//             io.println(
//               "Error(Nil), Ok(from_to_intermediate), Ok(intermediate_to_to): ",
//             )
//             io.println(
//               "from_to_intermediate: " <> string.inspect(from_to_intermediate),
//             )
//             io.println(
//               "intermediate_to_to: " <> string.inspect(intermediate_to_to),
//             )
//             io.println("updated_table: " <> string.inspect(updated_table))

//             updated_table
//           }

//           Ok(from_to_to), Ok(from_to_intermediate), Ok(intermediate_to_to) -> {
//             case from_to_to > { from_to_intermediate + intermediate_to_to } {
//               True -> {
//                 let updated_table =
//                   updated_table
//                   |> dict.upsert(update: #(from, to), with: fn(distance_maybe) {
//                     case distance_maybe {
//                       option.None -> from_to_intermediate + intermediate_to_to

//                       option.Some(distance) ->
//                         int.min(
//                           distance,
//                           from_to_intermediate + intermediate_to_to,
//                         )
//                     }
//                   })

//                 io.println("\n")
//                 io.println(
//                   "Ok(from_to_to), Ok(from_to_intermediate), Ok(intermediate_to_to): ",
//                 )
//                 io.println("from_to_to: " <> string.inspect(from_to_to))
//                 io.println(
//                   "from_to_intermediate: "
//                   <> string.inspect(from_to_intermediate),
//                 )
//                 io.println(
//                   "intermediate_to_to: " <> string.inspect(intermediate_to_to),
//                 )
//                 io.println(
//                   "from_to_to > { from_to_intermediate + intermediate_to_to } True",
//                 )
//                 io.println("updated_table: " <> string.inspect(updated_table))

//                 updated_table
//               }

//               False -> updated_table
//             }
//           }

//           _, _, _ -> updated_table
//         }
//       })
//     })
//   })
// }
