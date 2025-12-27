import gleam/int
import gleam/list

// Interval tuple: start and end time of a meeting
type Interval =
  #(Int, Int)

// Sort meetings by start time so overlap checks can be linear
fn sort_ascending(intervals: List(Interval)) -> List(Interval) {
  intervals
  |> list.sort(by: fn(interval1, interval2) {
    let #(start1, _end1) = interval1
    let #(start2, _end2) = interval2
    int.compare(start1, start2)
  })
}

// Walk sorted intervals, short-circuiting as soon as an overlap is found
fn check_for_overlap(
  sorted: List(Interval),
  prev_interval: Interval,
  overlaps: Bool,
) -> Bool {
  case sorted, overlaps {
    [], True | [], False | _sorted, True -> overlaps

    [curr_interval, ..rest_sorted], False -> {
      let #(curr_start, _curr_end) = curr_interval
      let #(_prev_start, prev_end) = prev_interval

      check_for_overlap(rest_sorted, curr_interval, prev_end > curr_start)
    }
  }
}

// Returns True if all meetings are non-overlapping, False otherwise
// T(n) = O(n * log(n))
// S(n) = O(n)
fn attend_meetings_without_conflict(intervals: List(Interval)) -> Bool {
  let initial_interval = #(-1, -1)
  let overlaps =
    sort_ascending(intervals) |> check_for_overlap(initial_interval, False)
  case overlaps {
    True -> False
    False -> True
  }
}

pub fn run() {
  let i1 = [#(0, 30), #(5, 10), #(15, 20)]
  // False
  echo attend_meetings_without_conflict(i1)

  let i2 = [#(7, 10), #(2, 4)]
  // True
  echo attend_meetings_without_conflict(i2)
}
