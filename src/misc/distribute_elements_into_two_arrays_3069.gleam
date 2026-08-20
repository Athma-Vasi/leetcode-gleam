import gleam/int
import gleam/list

fn distribute(nums: List(Int)) {
  // Split the array by index parity:
  // - even indexes go into the first list
  // - odd indexes go into the second list
  // This preserves the relative order of each group, and then we reverse
  // both groups before appending so the final list matches the required order.
  //
  // Time complexity: O(n)
  // Space complexity: O(n)
  let #(evens, odds) =
    nums
    |> list.index_fold(from: #([], []), with: fn(acc, num, index) {
      let #(evens, odds) = acc

      case int.is_even(index) {
        True -> #([num, ..evens], odds)
        False -> #(evens, [num, ..odds])
      }
    })

  evens
  |> list.reverse
  |> list.append(odds |> list.reverse)
}

pub fn run() {
  let n1 = [2, 1, 3]
  // [2,3,1]
  echo distribute(n1)

  let n2 = [5, 4, 3, 8]
  // [5,3,4,8]
  echo distribute(n2)
}
