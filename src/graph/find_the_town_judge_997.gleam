import gleam/dict
import gleam/list
import gleam/option

// incorrect

fn collect_persons(trusts) -> List(Int) {
  trusts
  |> list.fold(from: dict.new(), with: fn(acc, trust) {
    let #(person_a, person_b) = trust

    acc
    |> dict.insert(for: person_a, insert: [])
    |> dict.insert(for: person_b, insert: [])
  })
  |> dict.keys
}

fn build_degrees(
  trusts: List(#(Int, Int)),
) -> #(dict.Dict(Int, Int), dict.Dict(Int, Int)) {
  trusts
  |> list.fold(from: #(dict.new(), dict.new()), with: fn(acc, curr) {
    let #(out_degrees, in_degrees) = acc
    let #(person_a, person_b) = curr
    let out_degrees =
      out_degrees
      |> dict.upsert(update: person_a, with: fn(out_degree_maybe) {
        case out_degree_maybe {
          option.None -> 1
          option.Some(out_degree) -> out_degree + 1
        }
      })
    let in_degrees =
      in_degrees
      |> dict.upsert(update: person_b, with: fn(in_degree_maybe) {
        case in_degree_maybe {
          option.None -> 1
          option.Some(in_degree) -> in_degree + 1
        }
      })

    #(out_degrees, in_degrees)
  })
}

fn compare_degrees(
  degrees: #(dict.Dict(Int, Int), dict.Dict(Int, Int)),
  n: Int,
  people,
) {
  let #(out_degrees, in_degrees) = degrees

  people
  |> list.fold(from: -1, with: fn(acc, person) {
    case out_degrees |> dict.get(person), in_degrees |> dict.get(person) {
      Ok(out_degree), Ok(in_degree) -> {
        case out_degree == 0, in_degree == n - 1 {
          True, True -> person
          _, _ -> acc
        }
      }
      _, _ -> acc
    }
  })
}

fn t(n: Int, trusts: List(#(Int, Int))) {
  build_degrees(trusts) |> compare_degrees(n, collect_persons(trusts))
}

pub fn run() {
  let n1 = 3
  let t1 = [#(1, 3), #(2, 3), #(3, 1)]
  // -1
  echo t(n1, t1)

  let n2 = 3
  let t2 = [#(1, 3), #(2, 3)]
  // 3
  echo t(n2, t2)
}
