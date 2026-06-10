import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string

type LeftDigitResult =
  Result(Int, Nil)

type RightDigitResult =
  Result(Int, Nil)

type AdjacencyMap =
  dict.Dict(Int, #(LeftDigitResult, RightDigitResult))

fn convert_to_digits(num: Int) {
  num
  |> int.to_string
  |> string.to_graphemes
  |> list.fold(from: [], with: fn(digits, grapheme) {
    case int.parse(grapheme) {
      Error(Nil) -> digits
      Ok(digit) -> [digit, ..digits]
    }
  })
  |> list.reverse
}

fn build_range(num1: Int, num2: Int, result: List(Int)) {
  case num1 == num2 {
    True -> [num1, ..result] |> list.reverse
    False -> build_range(num1 + 1, num2, [num1, ..result])
  }
}

fn update_left_edge(
  graph: AdjacencyMap,
  left_digit_result: Result(Int, Nil),
  right_digit: Int,
) {
  graph
  |> dict.upsert(update: right_digit, with: fn(edges_maybe) {
    case left_digit_result, edges_maybe {
      Error(Nil), option.None -> #(Error(Nil), Error(Nil))

      Error(Nil), option.Some(edges) -> {
        let #(_left_edge_result, right_edge_result) = edges
        #(Error(Nil), right_edge_result)
      }

      Ok(left_digit), option.None -> #(Ok(left_digit), Error(Nil))

      Ok(left_digit), option.Some(edges) -> {
        let #(_left_edge_result, right_edge_result) = edges
        #(Ok(left_digit), right_edge_result)
      }
    }
  })
}

fn update_right_edge(
  graph: AdjacencyMap,
  left_digit_result: Result(Int, Nil),
  right_digit: Int,
) {
  case left_digit_result {
    Error(Nil) -> graph

    Ok(left_digit) ->
      graph
      |> dict.upsert(update: left_digit, with: fn(edges_maybe) {
        case edges_maybe {
          option.None -> #(Error(Nil), Ok(right_digit))

          option.Some(edges) -> {
            let #(left_edge_result, _right_edge_result) = edges
            #(left_edge_result, Ok(right_digit))
          }
        }
      })
  }
}

fn build_graph(digits: List(Int)) {
  let initial_prev_result = Error(Nil)
  let initial_graph: AdjacencyMap = dict.new()
  let initial_acc = #(initial_prev_result, initial_graph)

  let #(_prev_result, graph) =
    digits
    |> list.fold(from: initial_acc, with: fn(acc, digit) {
      let #(prev_result, graph) = acc

      let updated_graph =
        graph
        |> update_left_edge(prev_result, digit)
        |> update_right_edge(prev_result, digit)

      #(Ok(digit), updated_graph)
    })

  graph
}

fn build_graphs(range: List(Int)) {
  let initial_graphs: List(AdjacencyMap) = []

  range
  |> list.fold(from: initial_graphs, with: fn(graphs, num) {
    let graph = num |> convert_to_digits |> build_graph

    io.println("\n")
    io.println("num: " <> int.to_string(num))
    io.println("graph: " <> string.inspect(graph))

    [graph, ..graphs]
  })
  |> list.reverse
}

fn t(num1: Int, num2: Int) {
  //   let range = build_range(num1, num2, [])
  //   build_graphs(range)

  // duplicate digits are being overwritten in the graph, which is not correct.

  echo build_graph([1, 2, 1])
}

pub fn run() {
  let n1 = 120
  let n11 = 130
  t(n1, n11)
}
