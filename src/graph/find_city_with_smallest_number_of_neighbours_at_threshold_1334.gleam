import gleam/dict
import gleam/list
import gleam/option
import gleamy/priority_queue

fn build_graph(
  edges: List(#(Int, Int, Int)),
) -> dict.Dict(Int, List(#(Int, Int))) {
  edges
  |> list.fold(from: dict.new(), with: fn(acc, edge) {
    let #(from, to, weight) = edge

    acc
    |> dict.upsert(update: from, with: fn(tos_weights_maybe) {
      case tos_weights_maybe {
        option.None -> [#(to, weight)]
        option.Some(tos_weights) -> [#(to, weight), ..tos_weights]
      }
    })
    |> dict.upsert(update: to, with: fn(froms_weights_maybe) {
      case froms_weights_maybe {
        option.None -> [#(from, weight)]
        option.Some(froms_weights) -> [#(from, weight), ..froms_weights]
      }
    })
  })
}

fn t(_n: Int, edges: List(#(Int, Int, Int)), _distance_threshold: Int) {
  build_graph(edges)
}

pub fn run() {
  let n1 = 4
  let edges1 = [#(0, 1, 3), #(1, 2, 1), #(1, 3, 4), #(2, 3, 1)]
  let dt1 = 4
  let t1 = t(n1, edges1, dt1)
  // 3
  echo t1
}
