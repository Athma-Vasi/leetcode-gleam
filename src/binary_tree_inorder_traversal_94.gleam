import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import tree_node.{type TreeNode, TreeNode}

// T(n) = O(n)
// S(n) = O(n)

fn inorder_traversal(
  result_stack: List(Int),
  current: Option(TreeNode(Int)),
  working_stack: List(TreeNode(Int)),
) -> List(Int) {
  case current {
    None -> {
      case working_stack {
        [] -> result_stack |> list.reverse
        [node, ..rest] ->
          inorder_traversal([node.value, ..result_stack], node.right, rest)
      }
    }
    Some(node) ->
      inorder_traversal(result_stack, node.left, [node, ..working_stack])
  }
}

fn t(root: Option(TreeNode(Int))) {
  inorder_traversal([], root, [])
}

pub fn run() {
  let n5 =
    TreeNode(
      value: 5,
      left: Some(TreeNode(value: 3, left: None, right: None)),
      right: Some(TreeNode(value: 7, left: None, right: None)),
    )

  let n15 =
    TreeNode(
      value: 15,
      left: None,
      right: Some(TreeNode(value: 18, left: None, right: None)),
    )

  let root1 = Some(TreeNode(value: 10, left: Some(n5), right: Some(n15)))
  let r1 = t(root1)
  r1 |> list.map(fn(num) { int.to_string(num) |> io.println })
  Nil
}
