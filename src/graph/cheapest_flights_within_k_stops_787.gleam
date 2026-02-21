import gleam/dict
import gleam/list
import gleam/option
import gleam/result

// Flight tuple format: #(from_city, to_city, ticket_price)
// #(from, to, price)
type Flights =
  List(#(Int, Int, Int))

// Outgoing edge tuple format: #(to_city, ticket_price)
// #(to, price)
type Edges =
  List(#(Int, Int))

// Adjacency list keyed by source city.
// #(from, edges)
type AdjacencyList =
  dict.Dict(Int, Edges)

// Queue state: #(current_city, cumulative_cost, stops_used)
// #(current_city, total_cost_so_far, stops_taken)
type ItineraryQueue =
  List(#(Int, Int, Int))

// Best known cumulative cost per city encountered so far.
// #(city, min_cost)
type MinCostTable =
  dict.Dict(Int, Int)

// Builds a directed weighted adjacency list from the flight list.
//
// Complexity:
// - Time: O(F * log V), where F is number of flights and V is number of cities
//   appearing as `from` keys in the dictionary.
// - Space: O(F) for storing all edges.
fn build_graph(flights: Flights) -> AdjacencyList {
  flights
  |> list.fold(from: dict.new(), with: fn(graph, flight) {
    let #(from, to, price) = flight

    graph
    |> dict.upsert(update: from, with: fn(edges_maybe) {
      case edges_maybe {
        option.None -> [#(to, price)]
        option.Some(edges) -> [#(to, price), ..edges]
      }
    })
  })
}

// Traverses reachable routes using a queue of itinerary states while respecting
// the maximum stop limit `k`.
//
// Notes:
// - This function keeps the existing algorithm/behavior unchanged.
// - A path state is expanded only if its stop count is within the allowed limit.
// - When a cheaper cumulative cost for a city is found, that city state is
//   enqueued for further expansion.
//
// Complexity (with current immutable List queue):
// - Let S be number of enqueued states and E' be total edges scanned from those
//   states. Dictionary reads/writes are O(log V).
// - Time: O(E' * log V + enqueue_cost), where enqueue_cost can be O(S^2) in the
//   worst case due to repeated list.append on immutable lists.
// - Space: O(S + V) for queue states and min-cost dictionary.
fn breadth_first_traversal(
  graph: AdjacencyList,
  itinerary_queue: ItineraryQueue,
  destination: Int,
  min_cost_table: MinCostTable,
  k: Int,
) {
  case itinerary_queue {
    [] -> min_cost_table |> dict.get(destination) |> result.unwrap(or: -1)

    [itinerary, ..rest_queue] -> {
      let #(current_city, total_cost_so_far, stops_taken) = itinerary

      case stops_taken > k {
        True ->
          breadth_first_traversal(
            graph,
            rest_queue,
            destination,
            min_cost_table,
            k,
          )

        False -> {
          case graph |> dict.get(current_city) {
            Error(Nil) ->
              breadth_first_traversal(
                graph,
                rest_queue,
                destination,
                min_cost_table,
                k,
              )

            Ok(edges) -> {
              let #(updated_queue, updated_min_cost_table) =
                edges
                |> list.fold(
                  from: #(rest_queue, min_cost_table),
                  with: fn(acc, edge) {
                    let #(queue, min_cost_table) = acc
                    let #(destination_city, destination_cost) = edge
                    let new_total_cost = total_cost_so_far + destination_cost
                    let state = #(
                      destination_city,
                      new_total_cost,
                      stops_taken + 1,
                    )
                    let updated_queue = queue |> list.append([state])
                    let updated_min_cost_table =
                      min_cost_table
                      |> dict.insert(
                        for: destination_city,
                        insert: new_total_cost,
                      )

                    case min_cost_table |> dict.get(destination_city) {
                      Error(Nil) -> #(updated_queue, updated_min_cost_table)

                      Ok(min_cost) ->
                        case new_total_cost < min_cost {
                          True -> #(updated_queue, updated_min_cost_table)

                          False -> acc
                        }
                    }
                  },
                )

              breadth_first_traversal(
                graph,
                updated_queue,
                destination,
                updated_min_cost_table,
                k,
              )
            }
          }
        }
      }
    }
  }
}

// Entry point for solving "Cheapest Flights Within K Stops".
//
// Steps:
// 1) Build graph from flights.
// 2) Start traversal from source with cost 0 and 0 stops.
// 3) Return cheapest cost to destination or -1 if unreachable.
//
// End-to-end complexity:
// - Time: build_graph + traversal.
// - Space: graph + traversal state.
fn cheapest_flights(
  _n: Int,
  flights: Flights,
  source: Int,
  destination: Int,
  k: Int,
) {
  build_graph(flights)
  |> breadth_first_traversal([#(source, 0, 0)], destination, dict.new(), k)
}

pub fn run() {
  let n1 = 4
  let f1 = [
    #(0, 1, 100),
    #(1, 2, 100),
    #(2, 0, 100),
    #(1, 3, 600),
    #(2, 3, 200),
  ]
  let s1 = 0
  let d1 = 3
  let k1 = 1
  // 700
  echo cheapest_flights(n1, f1, s1, d1, k1)

  let n2 = 3
  let f2 = [#(0, 1, 100), #(1, 2, 100), #(0, 2, 500)]
  let s2 = 0
  let d2 = 2
  let k2 = 1
  // 200
  echo cheapest_flights(n2, f2, s2, d2, k2)

  let n3 = 3
  let f3 = [#(0, 1, 100), #(1, 2, 100), #(0, 2, 500)]
  let s3 = 0
  let d3 = 2
  let k3 = 0
  // 500
  echo cheapest_flights(n3, f3, s3, d3, k3)
}
