import gleam/option
import graph/tree_node

pub type RPNKind {
  Leaf(value: Int)
  Branch(value: Int)
}

fn traverse_and_create(
  rpn_stack: List(RPNKind),
  working_stack: List(tree_node.TreeNode(Int)),
) {
  case working_stack {
    [] -> rpn_stack

    [node, ..rest] ->
      case node.left, node.right {
        option.None, option.None ->
          traverse_and_create([Leaf(node.value), ..rpn_stack], rest)

        option.None, option.Some(right_node) ->
          traverse_and_create(
            [Branch(node.value + right_node.value), ..rpn_stack],
            [right_node, ..rest],
          )

        option.Some(left_node), option.None ->
          traverse_and_create(
            [Branch(node.value + left_node.value), ..rpn_stack],
            [left_node, ..rest],
          )

        option.Some(left_node), option.Some(right_node) ->
          traverse_and_create(
            [
              Branch(node.value + left_node.value + right_node.value),
              ..rpn_stack
            ],
            [right_node, left_node, ..rest],
          )
      }
  }
}

pub fn run() {
  let root1 =
    tree_node.TreeNode(
      value: 1,
      left: option.Some(tree_node.TreeNode(
        value: 2,
        left: option.Some(tree_node.TreeNode(
          value: 4,
          left: option.None,
          right: option.None,
        )),
        right: option.Some(tree_node.TreeNode(
          value: 5,
          left: option.None,
          right: option.None,
        )),
      )),
      right: option.Some(tree_node.TreeNode(
        value: 3,
        left: option.Some(tree_node.TreeNode(
          value: 6,
          left: option.None,
          right: option.None,
        )),
        right: option.None,
      )),
    )
  echo traverse_and_create([], [root1])
}
