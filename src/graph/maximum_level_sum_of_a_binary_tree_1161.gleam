import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import graph/tree_node

/// Updates or initializes the sum for a given tree level in the accumulator table.
/// Uses dict.upsert to either insert a new level sum or add to an existing one.
/// Time Complexity: O(log h) where h is the height (number of levels)
/// Space Complexity: O(1) amortized
fn update_table(levels_sums_table, level, value) {
  levels_sums_table
  |> dict.upsert(update: level, with: fn(level_sum_maybe) {
    case level_sum_maybe {
      option.None -> value
      option.Some(level_sum) -> level_sum + value
    }
  })
}

fn traverse_and_build(
  levels_sums_table: dict.Dict(Int, Int),
  stack: List(#(tree_node.TreeNode(Int), Int)),
) {
  case stack {
    [] -> levels_sums_table

    [top, ..rest] -> {
      // Extract the current node and its level from the stack
      let #(node, level) = top
      // Accumulate the current node's value to its level's sum
      let updated_table = levels_sums_table |> update_table(level, node.value)

      // Process nodes based on their availability
      case node.left, node.right {
        option.None, option.None -> traverse_and_build(updated_table, rest)

        option.None, option.Some(right_node) ->
          traverse_and_build(updated_table, [#(right_node, level + 1), ..rest])

        option.Some(left_node), option.None ->
          traverse_and_build(updated_table, [#(left_node, level + 1), ..rest])

        option.Some(left_node), option.Some(right_node) ->
          traverse_and_build(updated_table, [
            #(left_node, level + 1),
            #(right_node, level + 1),
            ..rest
          ])
      }
    }
  }
}

/// Performs iterative level-order traversal using a stack to accumulate level sums.
/// Returns a dictionary mapping tree levels to their corresponding sums.
/// Time Complexity: O(n log h) where n = nodes, h = height
///   - Visits each of n nodes once: O(n)
///   - Each update_table call: O(log h)
/// Space Complexity: O(h) for stack depth and dictionary storage
/// Sorts the level-sum pairs in descending order by sum value.
/// Returns a list of tuples (level, sum) ordered by sum from highest to lowest.
/// Time Complexity: O(h log h) where h is the number of levels
/// Space Complexity: O(h) for the converted list
fn sort_desc(levels_sums_table) {
  levels_sums_table
  |> dict.to_list
  |> list.sort(by: fn(tuple1, tuple2) {
    let #(_level1, sum1) = tuple1
    let #(_level2, sum2) = tuple2
    sum2 |> int.compare(with: sum1)
  })
}

/// Sorts the level-sum pairs in descending order by sum value.
/// Returns a list of tuples (level, sum) ordered by sum from highest to lowest.
fn maximum_level_sum(root: tree_node.TreeNode(Int)) {
  let #(level, _sum) =
    traverse_and_build(dict.new(), [#(root, 1)])
    |> sort_desc
    |> list.first
    |> result.unwrap(or: #(-1, -1))

  level
}

/// Finds the tree level with the maximum sum.
/// Traverses the tree, accumulates sums per level, sorts by sum (descending),
/// and returns the level number of the maximum sum level (1-indexed).
/// 
/// Overall Time Complexity: O(n log h)
///   - traverse_and_build: O(n log h) where n = total nodes, h = height
///   - sort_desc: O(h log h) where h = number of levels
///   - list.first: O(1)
///   - Total: O(n log h) since h ≤ n and typically h << n
///
/// Overall Space Complexity: O(h)
///   - Dictionary storage: O(h) for level sums
///   - Stack usage: O(h) for recursion depth
///   - Sorting overhead: O(h) for the sorted list
///
/// Best Case: Balanced tree with h = O(log n) → O(n log log n) time, O(log n) space
/// Worst Case: Skewed tree with h = O(n) → O(n²) time, O(n) space
pub fn run() {
  // Test case 1: Tree with levels containing both positive and negative values
  // Expected output: 2 (level 2 has sum 7 + (-8) = -1, but level 1 has 1, level 3 has 0)
  // Level 2 maximum sum is 7 (only left child)
  let root1 =
    tree_node.TreeNode(
      value: 1,
      left: option.Some(tree_node.TreeNode(
        value: 7,
        left: option.Some(tree_node.TreeNode(
          value: 7,
          left: option.None,
          right: option.None,
        )),
        right: option.Some(tree_node.TreeNode(
          value: -8,
          left: option.None,
          right: option.None,
        )),
      )),
      right: option.Some(tree_node.TreeNode(
        value: 0,
        left: option.None,
        right: option.None,
      )),
    )
  // Expected: 2 (level 2 sum = 7)
  echo maximum_level_sum(root1)

  // Test case 2: Right-skewed tree with large positive and negative integers
  let root2 =
    tree_node.TreeNode(
      value: 989,
      left: option.None,
      right: option.Some(tree_node.TreeNode(
        value: 10_250,
        left: option.Some(tree_node.TreeNode(
          value: 98_693,
          left: option.None,
          right: option.None,
        )),
        right: option.Some(tree_node.TreeNode(
          value: -89_388,
          left: option.None,
          right: option.Some(tree_node.TreeNode(
            value: -32_127,
            left: option.None,
            right: option.None,
          )),
        )),
      )),
    )
  // Expected: 2 (level 2 sum = 10250)
  echo maximum_level_sum(root2)
}
