import gleam/dict
import gleam/list
import gleam/option

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
