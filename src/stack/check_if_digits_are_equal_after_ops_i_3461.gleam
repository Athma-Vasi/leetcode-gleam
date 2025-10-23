import gleam/float
import gleam/int
import gleam/option
import gleam/result
import gleam/string

fn get_first_rest(str: String) {
  let first = str |> string.first |> result.unwrap(or: "")
  let rest = str |> string.drop_start(up_to: 1)

  #(first, rest)
}

fn check(s: String, prev: option.Option(String), result: String) {
  case s, prev {
    "", option.None -> ""
    "", option.Some(_prev) -> result

    // first iteration
    str, option.None -> {
      let #(first, rest) = get_first_rest(str)
      check(rest, option.Some(first), result)
    }

    // continuing iteration
    str, option.Some(prev) -> {
      let #(first, rest_str) = get_first_rest(str)

      case int.parse(prev), int.parse(first) {
        Ok(prev), Ok(first) -> {
          let num_str =
            int.to_float(prev + first)
            |> float.modulo(by: 10.0)
            |> result.unwrap(0.0)
            |> float.truncate
            |> int.to_string
          echo num_str

          check(
            rest_str,
            option.Some(num_str),
            result |> string.append(num_str),
          )
        }

        Error(Nil), Error(Nil) | Error(Nil), Ok(_first) | Ok(_prev), Error(Nil) -> {
          check(rest_str, option.None, result)
        }
      }
    }
  }
}

fn operate(s: String) {
  let computed_str = check(s, option.None, "")

  case string.length(computed_str) == 2 {
    True -> {
      let #(first, second) = get_first_rest(computed_str)
      first == second
    }

    False -> operate(computed_str)
  }
}

fn t(s: String) {
  //   operate(s)
  check(s, option.None, "")
}

pub fn run() {
  let s1 = "3902"
  t(s1)
  // true
  //   echo r1
}
