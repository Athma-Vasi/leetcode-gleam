import gleam/dict
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string

pub type Word =
  String

type AdjacencyList =
  dict.Dict(Word, set.Set(Word))

fn determine_if_differs_by_one_letter(comparee, compared) {
  let comparee_set =
    comparee
    |> string.to_graphemes
    |> set.from_list
  let union_set =
    compared
    |> string.to_graphemes
    |> list.fold(from: comparee_set, with: fn(letters_set, letter) {
      letters_set |> set.insert(letter)
    })
  let word_length = string.length(comparee)

  word_length + 1 == set.size(union_set)
}

fn build_graph(word_list: List(String)) {
  word_list
  |> list.fold(from: dict.new(), with: fn(graph, comparee) {
    word_list
    |> list.fold(from: graph, with: fn(graph, compared) {
      case comparee == compared {
        True -> graph

        False ->
          case determine_if_differs_by_one_letter(comparee, compared) {
            False -> graph

            True -> {
              graph
              |> dict.upsert(update: comparee, with: fn(adjacents_maybe) {
                case adjacents_maybe {
                  //   None -> [compared]
                  None -> set.new() |> set.insert(compared)
                  //   Some(adjacents) -> [compared, ..adjacents]
                  Some(adjacents) -> adjacents |> set.insert(compared)
                }
              })
              |> dict.upsert(update: compared, with: fn(adjacents_maybe) {
                case adjacents_maybe {
                  //   None -> [comparee]
                  None -> set.new() |> set.insert(comparee)
                  //   Some(adjacents) -> [comparee, ..adjacents]
                  Some(adjacents) -> adjacents |> set.insert(comparee)
                }
              })
            }
          }
      }
    })
  })
}

pub fn run() {
  let word_list1 = ["hot", "dot", "dog", "lot", "log", "cog"]
  build_graph(word_list1)
  |> dict.each(fn(key, value) {
    io.println("\n")
    io.println("key: " <> string.inspect(key))
    io.println("value: " <> string.inspect(value |> set.to_list))
  })
}
