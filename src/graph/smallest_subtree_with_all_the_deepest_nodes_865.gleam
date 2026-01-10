import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import graph/tree_node

// INCORRECT: Fix to BFS

fn update_table(
  level_nodes_table: dict.Dict(Int, List(tree_node.TreeNode(Int))),
  level: Int,
  node: tree_node.TreeNode(Int),
) {
  level_nodes_table
  |> dict.upsert(update: level, with: fn(nodes_maybe) {
    case nodes_maybe {
      option.None -> [node]
      option.Some(nodes) -> [node, ..nodes]
    }
  })
}

fn traverse_and_build(
  // mapping of descendant node to ancestor
  ancestor_table: dict.Dict(tree_node.TreeNode(Int), tree_node.TreeNode(Int)),
  level_nodes_table: dict.Dict(Int, List(tree_node.TreeNode(Int))),
  queue: List(#(Int, tree_node.TreeNode(Int))),
) {
  case queue {
    [] -> #(ancestor_table, level_nodes_table)

    [tuple, ..rest] -> {
      let #(level, node) = tuple

      let updated_level_nodes_table =
        update_table(level_nodes_table, level, node)

      case node.left, node.right {
        option.None, option.None ->
          traverse_and_build(ancestor_table, updated_level_nodes_table, rest)

        option.None, option.Some(right_node) ->
          traverse_and_build(
            ancestor_table |> dict.insert(right_node, node),
            updated_level_nodes_table,
            [#(level + 1, right_node), ..rest],
          )

        option.Some(left_node), option.None ->
          traverse_and_build(
            ancestor_table |> dict.insert(left_node, node),
            updated_level_nodes_table,
            [#(level + 1, left_node), ..rest],
          )

        option.Some(left_node), option.Some(right_node) ->
          traverse_and_build(
            ancestor_table
              |> dict.insert(left_node, node)
              |> dict.insert(right_node, node),
            updated_level_nodes_table,
            [#(level + 1, left_node), #(level + 1, right_node), ..rest],
          )
      }
    }
  }
}

fn grab_deepest(
  level_nodes_table: dict.Dict(Int, List(tree_node.TreeNode(Int))),
) {
  let #(_level, nodes) =
    level_nodes_table
    |> dict.to_list
    |> list.sort(by: fn(tuple1, tuple2) {
      let #(level1, _nodes1) = tuple1
      let #(level2, _values2) = tuple2
      level2 |> int.compare(with: level1)
    })
    |> list.first
    |> result.unwrap(or: #(-1, []))

  nodes
}

fn grab_random(nodes_set: set.Set(tree_node.TreeNode(Int))) {
  let initial =
    tree_node.TreeNode(value: -1, left: option.None, right: option.None)

  nodes_set
  |> set.fold(from: initial, with: fn(acc, node) {
    case acc.value < 0 {
      // first iteration, add found random
      True -> node
      // already found, continue
      False -> acc
    }
  })
}

fn find_smallest(
  nodes_set: set.Set(tree_node.TreeNode(Int)),
  ancestor_table: dict.Dict(tree_node.TreeNode(Int), tree_node.TreeNode(Int)),
) {
  case nodes_set |> set.size {
    1 -> grab_random(nodes_set)

    _ -> {
      let random_node = grab_random(nodes_set)

      case ancestor_table |> dict.get(random_node) {
        Error(Nil) -> random_node

        Ok(ancestor) ->
          find_smallest(
            nodes_set |> set.delete(random_node) |> set.insert(ancestor),
            ancestor_table,
          )
      }
    }
  }
}

fn t(root: tree_node.TreeNode(Int)) {
  let #(ancestor_table, level_values_table) =
    traverse_and_build(dict.new(), dict.new(), [#(1, root)])
  let deepest_values = grab_deepest(level_values_table)
  find_smallest(deepest_values |> set.from_list, ancestor_table)
}

pub fn run() {
  let root1 =
    tree_node.TreeNode(
      value: 3,
      left: option.Some(tree_node.TreeNode(
        value: 5,
        left: option.Some(tree_node.TreeNode(
          value: 6,
          left: option.None,
          right: option.None,
        )),
        right: option.Some(tree_node.TreeNode(
          value: 2,
          left: option.Some(tree_node.TreeNode(
            value: 7,
            left: option.None,
            right: option.None,
          )),
          right: option.Some(tree_node.TreeNode(
            value: 4,
            left: option.None,
            right: option.None,
          )),
        )),
      )),
      right: option.Some(tree_node.TreeNode(
        value: 1,
        left: option.Some(tree_node.TreeNode(
          value: 0,
          left: option.None,
          right: option.None,
        )),
        right: option.Some(tree_node.TreeNode(
          value: 8,
          left: option.None,
          right: option.None,
        )),
      )),
    )
  echo t(root1)
}
