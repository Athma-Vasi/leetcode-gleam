import gleam/list
import gleam/result

// T(n) = O(n)
// S(n) = O(n) 
fn two_sum(
  result: #(Int, Int),
  left_index: Int,
  right_index: Int,
  sliced: List(Int),
  target: Int,
) {
  case sliced, left_index >= right_index {
    // Exhausted search space
    [], True | [], False | _, True -> result

    nums, False -> {
      let left_num = nums |> list.first |> result.unwrap(or: 0)
      let right_num = nums |> list.last |> result.unwrap(or: 0)

      case left_num + right_num == target {
        // Found the pair; convert to 1-indexed
        True -> #(left_index + 1, right_index + 1)

        False ->
          case left_num + right_num < target {
            // Sum too small: move left pointer rightward
            True -> {
              let #(_only_left_num, without_left_num) =
                nums |> list.split(at: left_index)
              two_sum(
                result,
                left_index + 1,
                right_index,
                without_left_num,
                target,
              )
            }

            // Sum too big: move right pointer leftward
            False -> {
              let #(without_right_num, _only_right_num) =
                nums |> list.split(at: right_index)
              two_sum(
                result,
                left_index,
                right_index - 1,
                without_right_num,
                target,
              )
            }
          }
      }
    }
  }
}

fn t(nums: List(Int), target: Int) {
  two_sum(#(-1, -1), 0, list.length(nums) - 1, nums, target)
}

pub fn run() {
  let n1 = [2, 7, 11, 15]
  let t1 = 9
  // #(1, 2)
  echo t(n1, t1)

  let n2 = [2, 3, 4]
  let t2 = 6
  // #(1, 3)
  echo t(n2, t2)

  let n3 = [-1, 0]
  let t3 = -1
  // #(1, 2)
  echo t(n3, t3)
}
