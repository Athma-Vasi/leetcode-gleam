import gleam/option.{type Option}

pub type TreeNode(a) {
  TreeNode(value: a, left: Option(TreeNode(a)), right: Option(TreeNode(a)))
}
