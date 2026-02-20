import gleam/dict
import gleam/list
import gleam/option
import gleam/set

type Equations =
  List(#(String, String))

type Values =
  List(Float)

type Queries =
  List(#(String, String))

type Edges =
  List(#(String, Float))

type AdjacencyList =
  dict.Dict(String, Edges)

// Builds a bidirectional weighted graph from equations.
// For each equation a / b = k, we add:
// - a -> b with weight k
// - b -> a with weight 1 / k
//
// Time complexity: O(E), where E is the number of equations.
// Space complexity: O(V + E), for adjacency storage.
fn build_graph(
  graph: AdjacencyList,
  equations: Equations,
  values: Values,
) -> AdjacencyList {
  case equations, values {
    [], [] | [], _ | _, [] -> graph

    [equation, ..rest_equations], [value, ..rest_values] -> {
      let #(var_a, var_b) = equation

      build_graph(
        graph
          |> dict.upsert(update: var_a, with: fn(edges_maybe) {
            case edges_maybe {
              option.None -> [#(var_b, value /. 1.0)]
              option.Some(edges) -> [#(var_b, value /. 1.0), ..edges]
            }
          })
          |> dict.upsert(update: var_b, with: fn(edges_maybe) {
            case edges_maybe {
              option.None -> [#(var_a, 1.0 /. value)]
              option.Some(edges) -> [#(var_a, 1.0 /. value), ..edges]
            }
          }),
        rest_equations,
        rest_values,
      )
    }
  }
}

// Expands neighbors into the traversal stack while carrying the
// cumulative product from the original source variable.
//
// If the current node has accumulated weight `p` and an outgoing edge
// has weight `w`, the neighbor is pushed with `p * w`.
//
// Time complexity: O(d), where d is the degree of the current node.
// Space complexity: O(d), due to the pushed entries.
fn fold_into(edges: Edges, rest_stack, with accum_weight: Float) {
  edges
  |> list.fold(from: rest_stack, with: fn(stack, edge) {
    let #(variable, weight) = edge
    [#(variable, accum_weight *. weight), ..stack]
  })
}

// Performs iterative graph traversal (stack-based DFS) to answer one query.
//
// Each stack entry stores:
// - current variable
// - cumulative product from query source to that variable
//
// Returns:
// - computed ratio when destination is reached
// - -1.0 when traversal cannot resolve the destination
//
// Time complexity: O(V + E) in the worst case per query.
// Space complexity: O(V) for `visited` and traversal stack.
fn traverse(graph: AdjacencyList, stack, to: String, visited, answer: Float) {
  case stack {
    [] -> answer

    [tuple, ..rest_stack] -> {
      let #(variable, accum_weight) = tuple

      case graph |> dict.get(variable) {
        Error(Nil) -> -1.0

        Ok(edges) ->
          case visited |> set.contains(this: variable) {
            True -> traverse(graph, rest_stack, to, visited, -1.0)

            False ->
              case variable == to {
                True -> accum_weight

                False ->
                  traverse(
                    graph,
                    edges |> fold_into(rest_stack, with: accum_weight),
                    to,
                    visited |> set.insert(this: variable),
                    accum_weight,
                  )
              }
          }
      }
    }
  }
}

// Evaluates all queries using a prebuilt graph.
//
// Time complexity: O(Q * (V + E)) in the worst case.
// Space complexity: O(V), excluding the output list.
fn evaluate(graph, queries) {
  queries
  |> list.reverse
  |> list.fold(from: [], with: fn(result, query) {
    let #(from, to) = query
    let answer = traverse(graph, [#(from, 1.0)], to, set.new(), 1.0)
    [answer, ..result]
  })
}

// Builds the graph once, then evaluates all queries.
//
// Overall complexity:
// - Graph build: O(E)
// - Query processing: O(Q * (V + E)) worst case
// - Total: O(E + Q * (V + E))
//
// Space complexity: O(V + E), excluding output list.
fn t(equations: Equations, values: Values, queries: Queries) {
  build_graph(dict.new(), equations, values) |> evaluate(queries)
}

pub fn run() {
  let e1 = [#("a", "b"), #("b", "c")]
  let v1 = [2.0, 3.0]
  let q1 = [#("a", "c"), #("b", "a"), #("a", "e"), #("a", "a"), #("x", "x")]
  // [6.00000,0.50000,-1.00000,1.00000,-1.00000]
  echo t(e1, v1, q1)

  let e2 = [#("a", "b"), #("b", "c"), #("bc", "cd")]
  let v2 = [1.5, 2.5, 5.0]
  let q2 = [#("a", "c"), #("c", "b"), #("bc", "cd"), #("cd", "bc")]
  // [3.75000,0.40000,5.00000,0.20000]
  echo t(e2, v2, q2)

  let e3 = [#("a", "b")]
  let v3 = [0.5]
  let q3 = [#("a", "b"), #("b", "a"), #("a", "c"), #("x", "y")]
  // [0.50000,2.00000,-1.00000,-1.00000]
  echo t(e3, v3, q3)
}
