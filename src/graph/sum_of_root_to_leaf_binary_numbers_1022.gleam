import gleam/list
import gleam/option.{None, Some}
import graph/tree_node.{type TreeNode, TreeNode}

// Iterative DFS that records each root-to-leaf path as a list of bits.
// Time: O(n) nodes visited; Space: O(n) for stack + stored paths.
fn traverse_preorder(
  binaries: List(List(Int)),
  // #(node, path)
  stack: List(#(TreeNode(Int), List(Int))),
) -> List(List(Int)) {
  case stack {
    [] -> binaries

    [top, ..rest_stack] -> {
      let #(node, path) = top
      let updated_path = [node.value, ..path]

      case node.left, node.right {
        None, None ->
          traverse_preorder(
            [list.reverse(updated_path), ..binaries],
            rest_stack,
          )

        None, Some(right_node) ->
          traverse_preorder(binaries, [
            #(right_node, updated_path),
            ..rest_stack
          ])

        Some(left_node), None ->
          traverse_preorder(binaries, [#(left_node, updated_path), ..rest_stack])

        Some(left_node), Some(right_node) ->
          traverse_preorder(binaries, [
            #(left_node, updated_path),
            #(right_node, updated_path),
            ..rest_stack
          ])
      }
    }
  }
}

// Converts a binary list (MSB -> LSB) to an integer.
// Time: O(k) for k bits; Space: O(1) extra.
fn binary_to_int(bits: List(Int)) -> Int {
  bits
  |> list.fold(from: 0, with: fn(value, bit) { value * 2 + bit })
}

// Maps each binary list to its integer value.
// Time: O(total_bits); Space: O(m) for m results.
fn binaries_to_ints(binaries: List(List(Int))) -> List(Int) {
  binaries
  |> list.fold(from: [], with: fn(ints, bits) { [binary_to_int(bits), ..ints] })
}

// Sums all values.
// Time: O(m); Space: O(1) extra.
fn calculate_sum(ints: List(Int)) -> Int {
  ints
  |> list.fold(from: 0, with: fn(sum, int) { sum + int })
}

// Orchestrates traversal and aggregation.
// Time: O(n + total_bits); Space: O(n + total_bits) due to stored paths.
fn t(root: TreeNode(Int)) -> Int {
  traverse_preorder([], [#(root, [])])
  |> binaries_to_ints
  |> calculate_sum
}

pub fn run() {
  let r1 =
    TreeNode(
      1,
      Some(TreeNode(
        0,
        Some(TreeNode(0, None, None)),
        Some(TreeNode(1, None, None)),
      )),
      Some(TreeNode(
        1,
        Some(TreeNode(0, None, None)),
        Some(TreeNode(1, None, None)),
      )),
    )
  // 22
  echo t(r1)

  let r2 = TreeNode(0, None, None)
  // 0
  echo t(r2)

  let r3 = TreeNode(1, None, None)
  // 1
  echo t(r3)

  let r4 =
    TreeNode(1, Some(TreeNode(0, Some(TreeNode(1, None, None)), None)), None)
  // 5
  echo t(r4)

  let r5 =
    TreeNode(0, None, Some(TreeNode(1, None, Some(TreeNode(1, None, None)))))
  // 3
  echo t(r5)

  let r6 =
    TreeNode(
      1,
      Some(TreeNode(
        1,
        Some(TreeNode(0, None, None)),
        Some(TreeNode(1, None, None)),
      )),
      Some(TreeNode(0, None, Some(TreeNode(1, None, None)))),
    )
  // 18
  echo t(r6)
}
