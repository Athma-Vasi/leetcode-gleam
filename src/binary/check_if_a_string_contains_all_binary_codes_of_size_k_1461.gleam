import gleam/dict
import gleam/list
import gleam/set
import gleam/string

// Represents one traversal state in the expected-codes graph:
// (bit_value, level_from_root, path_identifier).
// (binary_node, height, path_id)
type State =
  #(String, Int, Int)

// Outgoing edges from one state to its 0-child and 1-child.
type Edges =
  #(State, State)

// Directed adjacency list keyed by state.
type AdjacencyList =
  dict.Dict(State, Edges)

// Builds a k-length substring by consuming from the current grapheme head.
// Time: O(size^2) due to repeated string concatenation.
// Space: O(size) for recursion + resulting substring.
fn take_k_elements(
  stack: List(String),
  size: Int,
  count: Int,
  collected: String,
) -> String {
  case count == size, stack {
    True, [] | True, [_top, ..] | False, [] -> collected

    False, [top, ..rest] ->
      take_k_elements(rest, size, count + 1, collected <> top)
  }
}

// Collects all distinct substrings of length `size` from the input grapheme list.
// Time: O(n * size^2), where n is grapheme count.
// Space: O(min(n, distinct_substrings)) for the set.
fn collect_existing_k_substrings(
  grapheme_stack: List(String),
  size: Int,
  substrings: set.Set(String),
) -> set.Set(String) {
  case grapheme_stack {
    [] -> substrings

    [grapheme, ..rest_stack] -> {
      let substring = take_k_elements(rest_stack, size, 1, grapheme)

      case string.length(substring) < size {
        True -> collect_existing_k_substrings(rest_stack, size, substrings)

        False ->
          collect_existing_k_substrings(
            rest_stack,
            size,
            substrings |> set.insert(this: substring),
          )
      }
    }
  }
}

// Builds the expected binary-code graph up to the requested depth.
// Each state expands to two descendants (0 and 1).
// Time: O(2^size)
// Space: O(2^size)
fn build_expected_binary_codes_graph(
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
        True ->
          build_expected_binary_codes_graph(updated_graph, rest_stack, size)

        False ->
          build_expected_binary_codes_graph(
            updated_graph,
            [left_descendant, right_descendant, ..rest_stack],
            size,
          )
      }
    }
  }
}

// Traverses the expected-codes graph and collects generated binary substrings.
// The graph is consumed (keys deleted) to avoid revisiting states.
// Time: O(size * 2^size)
// Space: O(size * 2^size) including collected substrings.
fn collect_expected_binary_substrings(
  graph_and_substrings: #(AdjacencyList, List(String)),
  stack: List(State),
  permutation: String,
) {
  let #(graph, binary_substrings) = graph_and_substrings

  case stack {
    [] -> #(graph, binary_substrings)

    [top, ..rest_stack] -> {
      let #(node, _height, _path_id) = top
      let updated_graph = graph |> dict.delete(top)

      case graph |> dict.get(top) {
        Error(Nil) ->
          collect_expected_binary_substrings(
            #(updated_graph, [permutation <> node, ..binary_substrings]),
            rest_stack,
            permutation |> string.slice(at_index: -1, length: 1),
          )

        Ok(edges) -> {
          let #(left_descendant, right_descendant) = edges

          collect_expected_binary_substrings(
            #(updated_graph, binary_substrings),
            [left_descendant, right_descendant, ..rest_stack],
            permutation <> node,
          )
        }
      }
    }
  }
}

// Builds two root components (starting from "0" and "1") and merges them
// into a single expected-substring graph.
// Time: O(2^size)
// Space: O(2^size)
fn build_binary_substring_islands_graph(size: Int) -> AdjacencyList {
  ["0", "1"]
  |> list.fold(from: dict.new(), with: fn(graph, bit) {
    case bit {
      "0" -> graph |> build_expected_binary_codes_graph([#(bit, 1, 1)], size)
      // "1"
      _ -> graph |> build_expected_binary_codes_graph([#(bit, 1, -1)], size)
    }
  })
}

// Repeatedly traverses remaining components until the graph is exhausted.
// Returns all expected substrings represented by the graph.
// Time: O(size * 2^size)
// Space: O(size * 2^size)
fn traverse_archipelago(
  graph_and_substrings: #(AdjacencyList, List(String)),
) -> List(String) {
  let #(graph, binary_substrings) = graph_and_substrings

  case dict.size(graph) == 0 {
    True -> binary_substrings

    False -> {
      // for island: "0"
      collect_expected_binary_substrings(#(graph, []), [#("0", 1, 1)], "")
      // for island: "1"
      |> collect_expected_binary_substrings([#("1", 1, -1)], "")
      |> traverse_archipelago
    }
  }
}

// Verifies every expected substring exists in the observed substring set.
// Time: O(m * log n), where m is expected count and n is observed count.
// Space: O(1) additional.
fn compare(
  existing_k_substrings: set.Set(String),
  with expected_k_substrings: List(String),
) -> Bool {
  expected_k_substrings
  |> list.fold(from: True, with: fn(_comparison, permutation) {
    existing_k_substrings |> set.contains(this: permutation)
  })
}

// Fast path for size == 1: input must contain both bits.
// Time: O(|str|)
// Space: O(1)
fn has_both_bits(str: String) -> Bool {
  ["0", "1"]
  |> list.fold(from: True, with: fn(_comparison, binary) {
    str |> string.contains(binary)
  })
}

// Main predicate for LeetCode 1461:
// returns True when all binary codes of length `size` are present in `str`.
// Time: O(n * size^2 + size * 2^size)
// Space: O(min(n, distinct_substrings) + size * 2^size)
fn has_all_binary_substrings(str: String, size: Int) -> Bool {
  case size == 1 {
    True -> has_both_bits(str)

    False -> {
      let permutations_islands_graph =
        build_binary_substring_islands_graph(size)
      let expected_k_substrings =
        traverse_archipelago(#(permutations_islands_graph, []))

      str
      |> string.to_graphemes
      |> collect_existing_k_substrings(size, set.new())
      |> compare(with: expected_k_substrings)
    }
  }
}

pub fn run() {
  let s1 = "00110110"
  let k1 = 2
  // True
  echo has_all_binary_substrings(s1, k1)

  let s2 = "0110"
  let k2 = 1
  // True
  echo has_all_binary_substrings(s2, k2)

  let s3 = "0110"
  let k3 = 2
  // False
  echo has_all_binary_substrings(s3, k3)
}
