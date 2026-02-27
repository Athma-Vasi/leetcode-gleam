import gleam/dict
import gleam/list
import gleam/set
import gleam/string

// (binary_node, height, path_id)
type State =
  #(String, Int, Int)

type Edges =
  #(State, State)

type AdjacencyList =
  dict.Dict(State, Edges)

fn slide_window(
  stack: List(String),
  size: Int,
  count: Int,
  collected: String,
) -> String {
  case count == size, stack {
    True, [] | True, [_top, ..] | False, [] -> collected

    False, [top, ..rest] ->
      slide_window(rest, size, count + 1, collected <> top)
  }
}

fn collect_existing_substring_permutations(
  grapheme_stack: List(String),
  size: Int,
  substrings: set.Set(String),
) -> set.Set(String) {
  case grapheme_stack {
    [] -> substrings

    [grapheme, ..rest_stack] -> {
      let substring = slide_window(rest_stack, size, 1, grapheme)

      case string.length(substring) < size {
        True ->
          collect_existing_substring_permutations(rest_stack, size, substrings)

        False ->
          collect_existing_substring_permutations(
            rest_stack,
            size,
            substrings |> set.insert(this: substring),
          )
      }
    }
  }
}

fn build_permutations_graph(
  graph: AdjacencyList,
  stack: List(#(String, Int, Int)),
  size: Int,
) -> AdjacencyList {
  case stack {
    [] -> graph

    [top, ..rest_stack] -> {
      let #(binary_node, height, path_id) = top
      let left_descendant = #("0", height + 1, path_id * 2)
      let right_descendant = #("1", height + 1, path_id * 2 + 1)
      let updated_graph =
        graph
        |> dict.insert(#(binary_node, height, path_id), #(
          left_descendant,
          right_descendant,
        ))

      case height + 1 == size {
        True -> build_permutations_graph(updated_graph, rest_stack, size)

        False ->
          build_permutations_graph(
            updated_graph,
            [left_descendant, right_descendant, ..rest_stack],
            size,
          )
      }
    }
  }
}

fn collect_permutations(
  tuple: #(AdjacencyList, List(String)),
  stack: List(State),
  permutation: String,
) {
  let #(graph, permutations) = tuple

  case stack {
    [] -> #(graph, permutations)

    [top, ..rest_stack] -> {
      let #(node, _height, _path_id) = top
      let updated_graph = graph |> dict.delete(top)

      case graph |> dict.get(top) {
        Error(Nil) ->
          collect_permutations(
            #(updated_graph, [permutation <> node, ..permutations]),
            rest_stack,
            permutation |> string.slice(at_index: -1, length: 1),
          )

        Ok(edges) -> {
          let #(left_descendant, right_descendant) = edges

          collect_permutations(
            #(updated_graph, permutations),
            [left_descendant, right_descendant, ..rest_stack],
            permutation <> node,
          )
        }
      }
    }
  }
}

fn build_binary_permutations_islands_graph(size: Int) -> AdjacencyList {
  ["0", "1"]
  |> list.fold(from: dict.new(), with: fn(graph, binary) {
    case binary {
      "0" -> graph |> build_permutations_graph([#(binary, 1, 1)], size)
      // "1"
      _ -> graph |> build_permutations_graph([#(binary, 1, -1)], size)
    }
  })
}

fn traverse_archipelago(tuple: #(AdjacencyList, List(String))) {
  let #(graph, permutations) = tuple

  case dict.size(graph) == 0 {
    True -> permutations

    False -> {
      // for island: "0"
      collect_permutations(#(graph, []), [#("0", 1, 1)], "")
      // for island: "1"
      |> collect_permutations([#("1", 1, -1)], "")
      |> traverse_archipelago
    }
  }
}

fn compare_permutations(
  existing_substring_permutations: set.Set(String),
  expected_substring_permutations: List(String),
) {
  expected_substring_permutations
  |> list.fold(from: True, with: fn(_comparison, permutation) {
    existing_substring_permutations |> set.contains(this: permutation)
  })
}

fn compare_if_size_is_one(str: String) {
  ["0", "1"]
  |> list.fold(from: True, with: fn(_comparison, binary) {
    str |> string.contains(binary)
  })
}

fn t(str: String, size: Int) {
  case size == 1 {
    True -> compare_if_size_is_one(str)

    False -> {
      let existing_substring_permutations =
        collect_existing_substring_permutations(
          string.to_graphemes(str),
          size,
          set.new(),
        )

      let initial_permutations = []
      let permutations_islands_graph =
        build_binary_permutations_islands_graph(size)
      let expected_substring_permutations =
        traverse_archipelago(#(permutations_islands_graph, initial_permutations))

      compare_permutations(
        existing_substring_permutations,
        expected_substring_permutations,
      )
    }
  }
}

pub fn run() {
  let s1 = "00110110"
  let k1 = 2
  // True
  echo t(s1, k1)

  let s2 = "0110"
  let k2 = 1
  // True
  echo t(s2, k2)

  let s3 = "0110"
  let k3 = 2
  // False
  echo t(s3, k3)
}
