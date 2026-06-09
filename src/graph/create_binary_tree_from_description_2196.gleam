import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/set

type Ancestor =
  Int

type Descendant =
  Int

type IsLeft =
  Int

type Description =
  #(Ancestor, Descendant, IsLeft)

type LeftDescendantMaybe =
  option.Option(Descendant)

type RightDescendantMaybe =
  option.Option(Descendant)

type AdjacencyList =
  dict.Dict(Ancestor, #(LeftDescendantMaybe, RightDescendantMaybe))

type DescendantsSet =
  set.Set(Int)

type ValuesSet =
  set.Set(Int)

// Builds an adjacency map from each parent value to its optional left and
// right child values. Each description is processed once and updates a single
// dictionary entry.
// Time complexity: O(n)
// Space complexity: O(n)
fn generate_binary_tree(from descriptions: List(Description)) {
  let initial_binary_tree: AdjacencyList = dict.new()

  descriptions
  |> list.fold(from: initial_binary_tree, with: fn(binary_tree, description) {
    let #(ancestor, descendant, is_left) = description

    case is_left {
      // false = right_descendant
      0 ->
        binary_tree
        |> dict.upsert(update: ancestor, with: fn(descendants_maybe) {
          case descendants_maybe {
            option.None -> #(option.None, option.Some(descendant))

            option.Some(descendants) -> {
              let #(left_descendant_maybe, _right_descendant_maybe) =
                descendants
              #(left_descendant_maybe, option.Some(descendant))
            }
          }
        })

      // 1 = true = left_descendant
      _ ->
        binary_tree
        |> dict.upsert(update: ancestor, with: fn(descendants_maybe) {
          case descendants_maybe {
            option.None -> #(option.Some(descendant), option.None)

            option.Some(descendants) -> {
              let #(_left_descendant_maybe, right_descendant_maybe) =
                descendants
              #(option.Some(descendant), right_descendant_maybe)
            }
          }
        })
    }
  })
}

// Collects every node value and every child value so the root can be found by
// set difference in a later pass.
// Time complexity: O(n log n)
// Space complexity: O(n)
fn generate_values_set_and_descendants_set(
  from descriptions: List(Description),
) {
  let initial_descendants_set: DescendantsSet = set.new()
  let initial_values_set: ValuesSet = set.new()
  let initial_acc = #(initial_descendants_set, initial_values_set)

  descriptions
  |> list.fold(from: initial_acc, with: fn(acc, description) {
    let #(descendants_set, values_set) = acc
    let #(ancestor, descendant, _is_left) = description

    #(
      descendants_set |> set.insert(descendant),
      values_set |> set.insert(ancestor) |> set.insert(descendant),
    )
  })
}

// The root is the only value that never appears as a descendant. This scan
// checks each value against the descendants set and returns the remaining one.
// Time complexity: O(n log n)
// Space complexity: O(n) auxiliary
fn determine_root(
  from descendants_set: DescendantsSet,
  and values_set: ValuesSet,
) {
  values_set
  |> set.difference(descendants_set)
  |> set.to_list
  |> list.first
  |> result.unwrap(or: -1)
}

// Produces the adjacency representation of the tree and the value of the root.
// Overall time complexity: O(n log n)
// Overall space complexity: O(n)
fn construct_tree_and_return_root(descriptions: List(Description)) {
  let binary_tree = generate_binary_tree(from: descriptions)
  let #(descendants_set, values_set) =
    generate_values_set_and_descendants_set(from: descriptions)
  let root = determine_root(from: descendants_set, and: values_set)

  #(binary_tree, root)
}

pub fn run() {
  let d1 = [
    #(20, 15, 1),
    #(20, 17, 0),
    #(50, 20, 1),
    #(50, 80, 0),
    #(80, 19, 1),
  ]
  echo construct_tree_and_return_root(d1)

  let d2 = [#(1, 2, 1), #(2, 3, 0), #(3, 4, 1)]
  echo construct_tree_and_return_root(d2)
}
