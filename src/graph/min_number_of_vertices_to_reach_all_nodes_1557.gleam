import gleam/dict
import gleam/list
import gleam/option

fn collect_nodes(edges) -> List(Int) {
  edges
  |> list.fold(from: dict.new(), with: fn(acc, edge) {
    let #(from, to) = edge

    acc
    |> dict.insert(for: from, insert: [])
    |> dict.insert(for: to, insert: [])
  })
  |> dict.keys
}

fn create_in_degree_table(edges: List(#(Int, Int))) -> dict.Dict(Int, Int) {
  edges
  |> list.fold(from: dict.new(), with: fn(in_degree_table, edge) {
    let #(_from, to) = edge

    in_degree_table
    |> dict.upsert(update: to, with: fn(in_degree_maybe) {
      case in_degree_maybe {
        option.None -> 1
        option.Some(in_degree) -> in_degree + 1
      }
    })
  })
}

fn find_nodes_without_in_degree(
  in_degree_table: dict.Dict(Int, Int),
  nodes: List(Int),
) -> List(Int) {
  nodes
  |> list.fold(from: [], with: fn(acc, node) {
    case in_degree_table |> dict.get(node) {
      Error(Nil) -> [node, ..acc]
      Ok(_in_degree) -> acc
    }
  })
}

fn t(_n, edges) {
  create_in_degree_table(edges)
  |> find_nodes_without_in_degree(collect_nodes(edges))
}

pub fn run() {
  let n1 = 6
  let edges1 = [#(0, 1), #(0, 2), #(2, 5), #(3, 4), #(4, 2)]
  let nodes = t(n1, edges1)
  echo nodes
}
