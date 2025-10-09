import gleam/dict
import gleam/list
import gleam/option

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
  town_judge: Int,
  person: Int,
) {
  case person == 0 {
    True -> town_judge
    False -> {
      let #(out_degrees, in_degrees) = degrees

      case out_degrees |> dict.get(person), in_degrees |> dict.get(person) {
        // person trusts nobody and everybody else trusts person
        Error(Nil), Ok(in_degree) -> {
          case in_degree == n - 1 {
            // found the town judge
            True -> compare_degrees(degrees, n, person, person - 1)
            False -> compare_degrees(degrees, n, town_judge, person - 1)
          }
        }
        _, _ -> compare_degrees(degrees, n, town_judge, person - 1)
      }
    }
  }
}

// T(n) = O(n + m) where n is the number of people and m is the length of trusts
// S(n) = O(n + m) 
fn t(n: Int, trusts: List(#(Int, Int))) {
  build_degrees(trusts) |> compare_degrees(n, -1, n)
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
