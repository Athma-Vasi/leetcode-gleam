import gleam/int
import gleam/list

// fn minimum_operations(nums: List(Int)) {
//   nums
//   |> list.fold(from: 0, with: fn(acc, num) {
//     let remainder = num % 3
//     case remainder {
//       1 | 2 -> acc + 1
//       _ -> acc
//     }
//   })
// }

fn minimum_operations_k(nums: List(Int), k: Int) {
  nums
  |> list.fold(from: 0, with: fn(acc, num) {
    let remainder = num % k
    acc + int.min(remainder, k - remainder)
  })
}

fn t(nums: List(Int), k: Int) {
  minimum_operations_k(nums, k)
}

pub fn run() {
  let n1 = [1, 2, 3, 4]
  // 3
  echo t(n1, 3)
}
