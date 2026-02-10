import gleam/dict
import gleam/int
import gleam/list
import gleam/option

fn update_freq_table(
  freq_table: dict.Dict(Int, Int),
  with num: Int,
) -> dict.Dict(Int, Int) {
  freq_table
  |> dict.upsert(update: num, with: fn(freq_maybe) {
    case freq_maybe {
      option.None -> 1
      option.Some(freq) -> freq + 1
    }
  })
}

fn longest_balanced(nums: List(Int)) {
  nums
  |> list.index_fold(from: 0, with: fn(max_length, _num, row_index) {
    let initial_odd_freq_table = dict.new()
    let initial_even_freq_table = dict.new()

    let #(new_max, _odd_freq_table, _even_freq_table) =
      nums
      |> list.index_fold(
        from: #(max_length, initial_odd_freq_table, initial_even_freq_table),
        with: fn(row_acc, num, column_index) {
          let #(max_length, odd_freq_table, even_freq_table) = row_acc

          let #(updated_odd_freq_table, updated_even_freq_table) = case
            num / 2 == 0
          {
            True -> #(
              odd_freq_table,
              even_freq_table |> update_freq_table(with: num),
            )

            False -> #(
              odd_freq_table |> update_freq_table(with: num),
              even_freq_table,
            )
          }

          let new_max = case
            dict.size(updated_odd_freq_table)
            == dict.size(updated_even_freq_table)
          {
            True -> int.max(max_length, column_index - row_index + 1)
            False -> max_length
          }

          #(new_max, updated_odd_freq_table, updated_even_freq_table)
        },
      )

    new_max
  })
}

pub fn run() {
  let n1 = [2, 5, 4, 3]
  // 4
  echo longest_balanced(n1)

  let n2 = [3, 2, 2, 5, 4]
  // 5
  echo longest_balanced(n2)

  let n3 = [1, 2, 3, 2]
  // 3
  echo longest_balanced(n3)
}
