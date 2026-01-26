/// Reconstruct Itinerary (LeetCode 332)
///
/// Given flight tickets as (from, to) pairs, rebuild an itinerary that:
/// - Uses every ticket exactly once
/// - Starts at "JFK"
/// - Is lexicographically smallest among all valid itineraries
///
/// Implementation notes (current approach):
/// - Builds an adjacency list keyed by origin with destination lists.
/// - Sorts destinations lexicographically and performs a DFS-like stack walk.
/// - Does not currently consume edges; revisits are prevented by deleting the origin key.
///
/// Complexity (current implementation):
/// - build_graph: O(E), E = number of tickets
/// - sort_ascending: O(d log d) per node (d = out-degree); worst-case O(E log E)
/// - reconstruct traversal: O(E) pushes/pops over the stack plus dictionary lookups.
/// Space: O(E) for adjacency plus O(E) for the stack/history.
import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/string

type From =
  String

type To =
  String

type Ticket =
  #(From, To)

type Tickets =
  List(Ticket)

type AdjacencyList =
  dict.Dict(From, List(To))

/// Build adjacency list from tickets.
/// Complexity: O(E) time, O(E) space.
fn build_graph(tickets: Tickets) -> AdjacencyList {
  tickets
  |> list.fold(from: dict.new(), with: fn(graph, ticket) {
    let #(from, to) = ticket

    graph
    |> dict.upsert(update: from, with: fn(itineraries_maybe) {
      case itineraries_maybe {
        option.None -> [to]
        option.Some(itineraries) -> [to, ..itineraries]
      }
    })
  })
}

fn sort_ascending(itineraries: List(To)) {
  itineraries
  |> list.sort(by: fn(itinerary1, itinerary2) {
    itinerary1 |> string.compare(itinerary2)
  })
}

/// Push destinations in order so lexicographically smallest is popped first.
fn add_to_stack(itineraries: List(To), stack: List(From)) {
  itineraries
  |> list.fold_right(from: stack, with: fn(stack_acc, itinerary) {
    [itinerary, ..stack_acc]
  })
}

fn reconstruct(graph: AdjacencyList, stack: List(From), history: List(To)) {
  case stack {
    [] -> history |> list.reverse

    [from, ..rest] ->
      case graph |> dict.get(from) {
        Error(Nil) -> graph |> reconstruct(rest, [from, ..history])

        Ok(itineraries) ->
          graph
          |> dict.delete(from)
          |> reconstruct(itineraries |> sort_ascending |> add_to_stack(rest), [
            from,
            ..history
          ])
      }
  }
}

/// Public helper to run reconstruction starting at "JFK".
/// Complexity: dominated by adjacency sort + traversal = O(E log E).
fn t(tickets: Tickets) {
  build_graph(tickets)
  |> reconstruct(["JFK"], [])
}

/// Format itinerary as a readable arrow-separated path.
fn format_itinerary(path: List(String)) -> String {
  path |> string.join(with: " -> ")
}

pub fn run() {
  io.println("=== Reconstruct Itinerary (332) Test Suite ===")

  let t1 = [#("MUC", "LHR"), #("JFK", "MUC"), #("SFO", "SJC"), #("LHR", "SFO")]
  // expected: ["JFK","MUC","LHR","SFO","SJC"]
  let p1 = t(t1)
  io.println("Test 1: basic chain")
  io.println("Expected: JFK -> MUC -> LHR -> SFO -> SJC")
  io.println("Got: " <> format_itinerary(p1))

  let t2 = [
    #("JFK", "SFO"),
    #("JFK", "ATL"),
    #("SFO", "ATL"),
    #("ATL", "JFK"),
    #("ATL", "SFO"),
  ]
  // expected: ["JFK","ATL","JFK","SFO","ATL","SFO"]
  let p2 = t(t2)
  io.println("\nTest 2: branching with return")
  io.println("Expected: JFK -> ATL -> JFK -> SFO -> ATL -> SFO")
  io.println("Got: " <> format_itinerary(p2))

  // Minimal single-ticket itinerary
  let t3 = [#("JFK", "AAA")]
  // expected: ["JFK","AAA"]
  let p3 = t(t3)
  io.println("\nTest 3: single ticket")
  io.println("Expected: JFK -> AAA")
  io.println("Got: " <> format_itinerary(p3))

  // Lexicographic choice when multiple outgoing edges from JFK
  let t4 = [#("JFK", "KUL"), #("JFK", "NRT"), #("NRT", "JFK")]
  let p4 = t(t4)
  io.println("\nTest 4: lexicographic choice")
  io.println("Expected: JFK -> KUL -> NRT -> JFK")
  io.println("Got: " <> format_itinerary(p4))

  // Simple cycle of two airports
  let t5 = [#("JFK", "ATL"), #("ATL", "JFK")]
  // expected: ["JFK","ATL","JFK"]
  let p5 = t(t5)
  io.println("\nTest 5: two-node cycle")
  io.println("Expected: JFK -> ATL -> JFK")
  io.println("Got: " <> format_itinerary(p5))

  // Multiple identical destinations; verify ordering preference
  let t6 = [#("JFK", "A"), #("JFK", "A"), #("A", "JFK")]
  // expected: ["JFK","A","JFK","A"]
  let p6 = t(t6)
  io.println("\nTest 6: duplicate destinations")
  io.println("Expected: JFK -> A -> JFK -> A")
  io.println("Got: " <> format_itinerary(p6))

  io.println("\n=== End of Test Suite ===")
}
