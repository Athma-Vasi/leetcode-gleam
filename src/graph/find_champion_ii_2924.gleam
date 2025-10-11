import gleam/dict
import gleam/list
import gleam/option
import gleam/result

fn build_in_degree_table(edges: List(#(Int, Int))) -> dict.Dict(Int, Int) {
  edges
  |> list.fold(from: dict.new(), with: fn(acc, edge) {
    let #(_from, to) = edge
    acc
    |> dict.upsert(update: to, with: fn(in_degree_maybe) {
      case in_degree_maybe {
        option.None -> 1
        option.Some(in_degree) -> in_degree + 1
      }
    })
  })
}

fn find_champion(
  in_degree_table: dict.Dict(Int, Int),
  result: List(Int),
  n: Int,
) {
  case n < 0, list.length(result) > 1 {
    // multiple teams with zero indegree
    True, True | False, True -> -1
    // finished processing
    True, False -> result |> list.first |> result.unwrap(or: -1)
    // continue processing    
    False, False -> {
      case in_degree_table |> dict.get(n) {
        Ok(_in_degree) -> find_champion(in_degree_table, result, n - 1)
        // team with zero indegree 
        Error(Nil) -> find_champion(in_degree_table, [n, ..result], n - 1)
      }
    }
  }
}

// T(n) = O(n + e)
// S(n) = O(n)
fn t(n: Int, edges: List(#(Int, Int))) -> Int {
  build_in_degree_table(edges) |> find_champion([], n - 1)
}

pub fn run() {
  let n1 = 3
  let edges1 = [#(0, 1), #(1, 2)]
  let t1 = t(n1, edges1)
  // 0
  echo t1

  let n2 = 4
  let edges2 = [#(0, 2), #(1, 3), #(1, 2)]
  let t2 = t(n2, edges2)
  // -1
  echo t2
}
