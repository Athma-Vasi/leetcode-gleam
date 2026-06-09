import gleam/list

/// Computes the maximum total subarray value by taking the difference between
/// the global maximum and minimum values in the list, then multiplying by k.
///
/// Approach:
/// - Scan the list once while tracking current minimum and maximum.
/// - Return (max - min) * k.
///
/// Time Complexity: O(n), where n is the number of elements in nums.
/// Space Complexity: O(1), excluding the input list.
fn find_max_total_subarray_value(nums: List(Int), k: Int) {
  let max_signed_32_bit_integer = 2_147_483_647
  let min_signed_32_bit_integer = -2_147_483_648

  let #(min, max) =
    nums
    |> list.fold(
      from: #(max_signed_32_bit_integer, min_signed_32_bit_integer),
      with: fn(acc, num) {
        let #(min, max) = acc

        case num < min, num > max {
          True, False -> #(num, max)
          False, True -> #(min, num)
          True, True -> #(num, num)
          False, False -> #(min, max)
        }
      },
    )

  { max - min } * k
}

pub fn run() {
  let n1 = [1, 3, 2]
  let k1 = 2
  // 4
  echo find_max_total_subarray_value(n1, k1)

  let n2 = [4, 2, 5, 1]
  let k2 = 3
  // 12
  echo find_max_total_subarray_value(n2, k2)
}
