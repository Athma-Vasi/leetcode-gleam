import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import tree_node.{type TreeNode, TreeNode}

// T(n) = O(n)
// S(n) = O(n)

pub fn inorder_traverse(
  curr_original: Option(TreeNode(Int)),
  curr_cloned: Option(TreeNode(Int)),
  original_stack: List(TreeNode(Int)),
  cloned_stack: List(TreeNode(Int)),
  target: TreeNode(Int),
) {
  case curr_original, curr_cloned {
    None, None ->
      case original_stack, cloned_stack {
        [top_original, ..rest_originals], [top_cloned, ..rest_cloneds] -> {
          case target.value == top_original.value {
            True -> Some(top_cloned)
            False ->
              inorder_traverse(
                top_original.right,
                top_cloned.right,
                rest_originals,
                rest_cloneds,
                target,
              )
          }
        }
        _, _ -> None
      }

    Some(original_node), Some(cloned_node) ->
      inorder_traverse(
        original_node.left,
        cloned_node.left,
        [original_node, ..original_stack],
        [cloned_node, ..cloned_stack],
        target,
      )

    _, _ -> None
  }
}

pub fn t(original: TreeNode(Int), cloned: TreeNode(Int), target: TreeNode(Int)) {
  inorder_traverse(Some(original), Some(cloned), [], [], target)
}

pub fn run() {
  let o6 = TreeNode(value: 6, left: None, right: None)
  let o19 = TreeNode(value: 19, left: None, right: None)
  let o3 = TreeNode(value: 3, left: Some(o6), right: Some(o19))
  let o4 = TreeNode(value: 4, left: None, right: None)
  let o_root1 = TreeNode(value: 7, left: Some(o4), right: Some(o3))

  let c6 = TreeNode(value: 6, left: None, right: None)
  let c19 = TreeNode(value: 19, left: None, right: None)
  let c3 = TreeNode(value: 3, left: Some(c6), right: Some(c19))
  let c4 = TreeNode(value: 4, left: None, right: None)
  let c_root1 = TreeNode(value: 7, left: Some(c4), right: Some(c3))

  let r1 = t(o_root1, c_root1, o3)
  case r1 {
    None -> Nil
    Some(v) -> v.value |> int.to_string |> io.println
  }
}
