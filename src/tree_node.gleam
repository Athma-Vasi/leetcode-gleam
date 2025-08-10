import gleam/option.{type Option, None}

pub type TreeNode(a) {
  TreeNode(value: a, left: Option(TreeNode(a)), right: Option(TreeNode(a)))
}

pub fn make(
  value: a,
  left: Option(TreeNode(a)),
  right: Option(TreeNode(a)),
) -> TreeNode(a) {
  TreeNode(value: value, left: left, right: right)
}
