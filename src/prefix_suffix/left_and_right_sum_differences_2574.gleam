import gleam/int
import gleam/list

type SumsKind {
  Prefix
  Suffix
}

// Builds cumulative sums in one pass using an accumulator. Values are
// prepended in O(1), then reversed once to restore left-to-right order.
// Time complexity: O(n)
// Space complexity: O(n)
fn accumulate_sums(from nums: List(Int)) {
  let initial_prev = 0
  let initial_prefix_sums = []
  let initial_acc = #(initial_prev, initial_prefix_sums)
  let length = list.length(nums)

  let #(_prev, sums) =
    nums
    |> list.index_fold(from: initial_acc, with: fn(acc, num, index) {
      let #(prev, sums) = acc

      case index == 0 {
        True -> #(num, [num, 0, ..sums])
        False -> #(prev + num, [prev + num, ..sums])
      }
    })

  sums |> list.reverse |> list.take(up_to: length)
}

// Produces either prefix or suffix cumulative sums.
// Suffix sums are computed by reversing the input, reusing prefix logic, then
// reversing the result back.
// Time complexity: O(n)
// Space complexity: O(n)
fn create_sums(nums: List(Int), sums_kind: SumsKind) {
  case sums_kind {
    Prefix -> accumulate_sums(from: nums)

    Suffix -> nums |> list.reverse |> accumulate_sums |> list.reverse
  }
}

// Computes the absolute difference between aligned prefix and suffix sums.
// Differences are prepended during recursion and reversed once at completion.
// Time complexity: O(n)
// Space complexity: O(n)
fn find_differences(sums: #(List(Int), List(Int)), differences: List(Int)) {
  let #(prefix_sums, suffix_sums) = sums

  case prefix_sums, suffix_sums {
    [], [] -> list.reverse(differences)

    [prefix_sum, ..rest_prefix_sums], [suffix_sum, ..rest_suffix_sums] ->
      find_differences(#(rest_prefix_sums, rest_suffix_sums), [
        int.absolute_value(prefix_sum - suffix_sum),
        ..differences
      ])

    _, _ -> find_differences(sums, differences)
  }
}

// Returns the left-right absolute sum difference for every position.
// Overall time complexity: O(n)
// Overall space complexity: O(n)
fn t(nums: List(Int)) {
  let prefix_sums = create_sums(nums, Prefix)
  let suffix_sums = create_sums(nums, Suffix)
  find_differences(#(prefix_sums, suffix_sums), [])
}

pub fn run() {
  let n1 = [10, 4, 8, 3]
  // [15, 1, 11, 22]
  echo t(n1)

  let n2 = [1]
  // [0]
  echo t(n2)
}
