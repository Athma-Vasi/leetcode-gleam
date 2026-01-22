import gleam/list
import gleam/set

fn unlock_room(rooms: List(List(Int)), key) {
  rooms
  |> list.index_fold(from: [], with: fn(acc, curr, index) {
    case index == key {
      True -> curr
      False -> acc
    }
  })
}

fn visit_rooms(rooms: List(List(Int)), stack: List(Int), visited: set.Set(Int)) {
  case stack {
    [] -> set.size(visited) == list.length(rooms)
    [key, ..rest] -> {
      case visited |> set.contains(key) {
        True -> visit_rooms(rooms, rest, visited)

        False -> {
          let new_keys = unlock_room(rooms, key)
          let new_stack =
            new_keys
            |> list.fold(from: stack, with: fn(acc, key) { [key, ..acc] })
          visit_rooms(rooms, new_stack, visited |> set.insert(key))
        }
      }
    }
  }
}

// T(n) = O(n + m) where n is the number of rooms and m is the total number of keys
// S(n) = O(n)
fn t(rooms: List(List(Int))) {
  visit_rooms(rooms, [0], set.new())
}

pub fn run() {
  let rooms1 = [[1], [2], [3], []]
  let t1 = t(rooms1)
  // true
  echo t1

  let rooms2 = [[1, 3], [3, 0, 1], [2], [0]]
  let t2 = t(rooms2)
  // false
  echo t2
}
