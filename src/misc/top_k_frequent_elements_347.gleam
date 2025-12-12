import gleam/dict
import gleam/int
import gleam/list
import gleam/option

fn make_freq_table(nums: List(Int)) {
  nums
  |> list.fold(from: dict.new(), with: fn(table, num) {
    table
    |> dict.upsert(update: num, with: fn(freq_maybe) {
      case freq_maybe {
        option.None -> 1
        option.Some(freq) -> freq + 1
      }
    })
  })
}

fn sort_desc_by_freq(freq_table: dict.Dict(Int, Int)) {
  freq_table
  |> dict.to_list
  |> list.sort(by: fn(tuple1, tuple2) {
    let #(_num1, freq1) = tuple1
    let #(_num2, freq2) = tuple2
    int.compare(freq2, freq1)
  })
}

fn grab_upto(sorted: List(#(Int, Int)), k: Int) {
  sorted
  |> list.take(up_to: k)
  |> list.fold(from: [], with: fn(top_ks, tuple) {
    let #(num, _freq) = tuple
    [num, ..top_ks]
  })
}

// T(n) = O(n * log(n))
// S(n) = O(n)
fn t(nums: List(Int), k: Int) {
  make_freq_table(nums)
  |> sort_desc_by_freq
  |> grab_upto(k)
}

pub fn run() {
  let n1 = [1, 1, 1, 2, 2, 3]
  let k1 = 2
  // [2, 1]
  echo t(n1, k1)

  let n2 = [1]
  let k2 = 1
  // [1]
  echo t(n2, k2)
}
