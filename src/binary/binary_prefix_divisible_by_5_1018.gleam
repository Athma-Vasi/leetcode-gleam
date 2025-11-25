import gleam/float
import gleam/int
import gleam/list
import gleam/result

fn binary_to_int(binary: List(Int)) -> Int {
  binary
  |> list.reverse
  |> list.index_fold(from: 0, with: fn(acc, digit, index) {
    acc
    + {
      digit
      * {
        int.power(2, int.to_float(index))
        |> result.unwrap(or: 0.0)
        |> float.truncate
      }
    }
  })
}

fn create_subarrays(binary: List(Int)) -> List(List(Int)) {
  binary
  |> list.index_fold(from: [], with: fn(acc, _digit, index) {
    let sliced = binary |> list.take(index + 1)
    acc |> list.append([sliced])
  })
}

fn evaluate_subarrays(subarrays: List(List(Int))) -> List(Bool) {
  subarrays
  |> list.fold(from: [], with: fn(acc, subarray) {
    let integer = binary_to_int(subarray)
    let is_divisible = integer % 5 == 0
    acc |> list.append([is_divisible])
  })
}

fn t(binary: List(Int)) -> List(Bool) {
  create_subarrays(binary) |> evaluate_subarrays
}

pub fn run() {
  let b1 = [0, 1, 1]
  // [true, false, false]
  echo t(b1)

  let b2 = [1, 1, 1]
  // [false, false, false]
  echo t(b2)
}
