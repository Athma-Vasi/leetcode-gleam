import gleam/dict
import gleam/io
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

fn collect_next_k_elements(
  stack: List(String),
  size: Int,
  count: Int,
  collected: String,
) {
  case count == size, stack {
    True, [] | True, [_top, ..] | False, [] -> collected

    False, [top, ..rest] -> {
      let new_count = count + 1
      let new_collected = collected <> top

      // io.println("\n")
      io.println("new_count: " <> string.inspect(new_count))
      io.println("new_collected: " <> new_collected)

      collect_next_k_elements(rest, size, new_count, new_collected)
    }
  }
}

fn slide_window(
  grapheme_stack: List(String),
  size: Int,
  substrings: set.Set(String),
) {
  case grapheme_stack {
    [] -> substrings

    [grapheme, ..rest_stack] -> {
      let substring = collect_next_k_elements(rest_stack, size, 1, grapheme)

      io.println("\n")
      io.println("grapheme_stack: " <> string.inspect(grapheme_stack))
      io.println("substring: " <> substring)

      case string.length(substring) < size {
        True -> slide_window(rest_stack, size, substrings)
        False ->
          slide_window(
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
) {
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

      io.println("\n")
      io.println("stack: " <> string.inspect(stack))
      io.println("top: " <> string.inspect(top))
      io.println("left_descendant: " <> string.inspect(left_descendant))
      io.println("right_descendant: " <> string.inspect(right_descendant))
      io.println("height: " <> string.inspect(height))
      io.println("binary_node: " <> string.inspect(binary_node))
      io.println("updated_graph: " <> string.inspect(updated_graph))
      io.println("rest_stack: " <> string.inspect(rest_stack))
      io.println("path_id: " <> string.inspect(path_id))

      case height + 1 == size {
        True -> {
          build_permutations_graph(updated_graph, rest_stack, size)
        }

        False -> {
          build_permutations_graph(
            updated_graph,
            [left_descendant, right_descendant, ..rest_stack],
            size,
          )
        }
      }
    }
  }
}

fn collect_permutations(
  graph: AdjacencyList,
  stack: List(State),
  permutations: List(String),
) {
  case stack {
    [] -> permutations

    [top, ..rest_stack] -> {
      let #(node, _height, _path_id) = top

      case graph |> dict.get(top) {
        Error(Nil) -> collect_permutations(graph, rest_stack, permutations)

        Ok(edges) -> {
          let #(left_descendant, right_descendant) = edges

          collect_permutations(
            graph,
            [left_descendant, right_descendant, ..rest_stack],
            [node, ..permutations],
          )
        }
      }
    }
  }
}

fn build_binary_permutations_islands(size: Int) -> AdjacencyList {
  ["0", "1"]
  |> list.fold(from: dict.new(), with: fn(graph, binary) {
    case binary {
      "0" -> graph |> build_permutations_graph([#(binary, 1, 1)], size)
      // "1"
      _ -> graph |> build_permutations_graph([#(binary, 1, -1)], size)
    }
  })
}

fn t(str: String, size: Int) {
  str |> string.to_graphemes |> slide_window(size, set.new())
}

pub fn run() {
  let s1 = "00110110"
  let k1 = 3
  // true
  // echo t(s1, k1)
  echo build_binary_permutations_islands(k1)
    |> dict.each(fn(key, value) {
      io.println("\n")
      io.println("key: " <> string.inspect(key))
      io.println("value: " <> string.inspect(value))
    })
  // |> collect_permutations([#("0", 1, 0)], [])
}
