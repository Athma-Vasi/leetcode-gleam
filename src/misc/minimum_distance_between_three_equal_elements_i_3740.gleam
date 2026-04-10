import gleam/list

fn minimum_distance(nums: List(Int)) {
  nums
  |> list.index_fold(from: -1, with: fn(result, outer_num, outer_index) {
    nums
    |> list.index_fold(from: result, with: fn(result, middle_num, middle_index) {
      nums
      |> list.index_fold(from: result, with: fn(result, inner_num, inner_index) {
        case outer_index == middle_index || middle_index == inner_index {
          True -> result
          False -> {
            let is_good = outer_num == middle_num && middle_num == inner_num
          }
        }
      })
    })
  })
}
