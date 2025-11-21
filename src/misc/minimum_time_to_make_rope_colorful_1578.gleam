import gleam/list
import gleam/option
import gleam/result
import gleam/string

fn get_first_and_rest_colours(colours: String) {
  let colour = string.first(colours) |> result.unwrap("")
  let rest_colours = colours |> string.drop_start(up_to: 1)
  #(colour, rest_colours)
}

fn get_first_and_rest_times(needed_time: List(Int)) {
  let removal_time = list.first(needed_time) |> result.unwrap(0)
  let rest_times = needed_time |> list.drop(up_to: 1)
  #(removal_time, rest_times)
}

// T(n) = O(n)
// S(n) = O(1)
fn process_rope(
  min_time: Int,
  prev_maybe: option.Option(#(String, Int)),
  colours: String,
  needed_time: List(Int),
) {
  case prev_maybe, colours {
    // base case
    option.None, "" | option.Some(_prev_tuple), "" -> min_time

    // start of operation - add to prev and continue
    option.None, colours -> {
      let #(curr_colour, rest_colours) = get_first_and_rest_colours(colours)
      let #(curr_removal_time, rest_times) =
        get_first_and_rest_times(needed_time)

      process_rope(
        min_time,
        option.Some(#(curr_colour, curr_removal_time)),
        rest_colours,
        rest_times,
      )
    }

    // continuation of operation
    option.Some(prev_tuple), colours -> {
      let #(prev_colour, prev_removal_time) = prev_tuple
      let #(curr_colour, rest_colours) = get_first_and_rest_colours(colours)
      let #(curr_removal_time, rest_times) =
        get_first_and_rest_times(needed_time)

      case prev_colour == curr_colour {
        // found duplicate colour
        True -> {
          // add the smaller removal time
          let new_min_time = case prev_removal_time < curr_removal_time {
            True -> min_time + prev_removal_time
            False -> min_time + curr_removal_time
          }

          process_rope(
            new_min_time,
            option.Some(#(curr_colour, curr_removal_time)),
            rest_colours,
            rest_times,
          )
        }

        // continue processing with curr as prev        
        False -> {
          process_rope(
            min_time,
            option.Some(#(curr_colour, curr_removal_time)),
            rest_colours,
            rest_times,
          )
        }
      }
    }
  }
}

fn t(colours: String, needed_time: List(Int)) {
  process_rope(0, option.None, colours, needed_time)
}

pub fn run() {
  let c1 = "abaac"
  let t1 = [1, 2, 3, 4, 5]
  // 3
  echo t(c1, t1)

  let c2 = "abc"
  let t2 = [1, 2, 3]
  // 0
  echo t(c2, t2)

  let c3 = "aabaa"
  let t3 = [1, 2, 3, 4, 1]
  // 2
  echo t(c3, t3)
}
