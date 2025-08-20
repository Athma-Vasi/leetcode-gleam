import gleam/dict.{type Dict}
import gleam/list
import gleam/pair
import gleam/result

// incorrect

fn build_degrees(trusts: List(#(Int, Int))) {
  trusts
  |> list.fold(from: #(dict.new(), dict.new()), with: fn(acc, curr) {
    let person_a = pair.first(curr)
    let person_b = pair.second(curr)
    let out_degrees = pair.first(acc)
    let in_degrees = pair.second(acc)
    let new_out = { out_degrees |> dict.get(person_a) |> result.unwrap(0) } + 1
    let new_in = { in_degrees |> dict.get(person_b) |> result.unwrap(0) } + 1

    #(
      out_degrees |> dict.insert(person_a, new_out),
      in_degrees |> dict.insert(person_b, new_in),
    )
  })
}

fn compare_degrees(degrees: #(Dict(Int, Int), Dict(Int, Int)), n: Int) {
  let out_degrees = pair.first(degrees)
  let in_degrees = pair.second(degrees)

  out_degrees
  |> dict.fold(from: -1, with: fn(acc, person, out_degree) {
    let in_degree = in_degrees |> dict.get(person) |> result.unwrap(-2)
    case out_degree == 0 && in_degree == n - 1 {
      True -> person
      False -> acc
    }
  })
}

fn t(n: Int, trusts: List(#(Int, Int))) {
  build_degrees(trusts) |> compare_degrees(n)
}

pub fn run() {
  let n1 = 2
  let t1 = [#(1, 2)]
  t(n1, t1)
}
