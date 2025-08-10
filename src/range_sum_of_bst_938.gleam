import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import tree_node.{type TreeNode, TreeNode}

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
  let root1 = TreeNode(value: 10, left: Some(n5), right: Some(n15))
  let r1 = t(root1, 7, 15)
  r1 |> int.to_string |> io.println
}

fn t(root: TreeNode(Int), low: Int, high: Int) {
  inorder_traverse(0, Some(root), [], low, high)
}

fn inorder_traverse(
  result: Int,
  curr: Option(TreeNode(Int)),
  working_stack: List(TreeNode(Int)),
  low: Int,
  high: Int,
) {
  case curr {
    None -> {
      case working_stack {
        [] -> result
        [top, ..rest] ->
          inorder_traverse(
            case top.value >= low && top.value <= high {
              True -> result + top.value
              False -> result
            },
            top.right,
            rest,
            low,
            high,
          )
      }
    }
    Some(node) ->
      inorder_traverse(result, node.left, [node, ..working_stack], low, high)
  }
}
