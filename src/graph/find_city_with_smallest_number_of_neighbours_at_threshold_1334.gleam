import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string

type From =
  Int

type To =
  Int

type Distance =
  Int

type BiDirectionalEdge =
  #(From, To, Distance)

type BiDirectionalEdges =
  List(BiDirectionalEdge)

type AdjacencyList =
  dict.Dict(From, List(#(To, Distance)))

type DistancesTable =
  dict.Dict(#(From, To), Distance)

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
// fn build_distances_table(
//   bi_directional_edges: BiDirectionalEdges,
// ) -> DistancesTable {
//   bi_directional_edges
//   |> list.fold(from: dict.new(), with: fn(table, edge) {
//     let #(from, to, distance) = edge

//     table
//     |> dict.insert(for: #(from, from), insert: 0)
//     |> dict.insert(for: #(from, to), insert: distance)
//   })
// }

// fn floyd_warshall_traversal(distances_table: DistancesTable, n: Int) {
//   let #(intermediates, froms, tos) = #(
//     list.range(1, n),
//     list.range(1, n),
//     list.range(1, n),
//   )

//   intermediates
//   |> list.fold(from: distances_table, with: fn(updated_table, intermediate) {
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
//           distances_table |> dict.get(#(from, to)),
//           distances_table |> dict.get(#(from, intermediate)),
//           distances_table |> dict.get(#(intermediate, to))
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
