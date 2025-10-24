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
    // end condition
    "", option.None | "", option.Some(_prev) -> result

    // first iteration
    str, option.None -> {
      let #(first, rest) = get_first_rest(str)
      // continue checking with first character as previous
      check(rest, option.Some(first), result)
    }

    // continuing iteration
    str, option.Some(prev) -> {
      let #(first, rest_str) = get_first_rest(str)

      case int.parse(prev), int.parse(first) {
        // both numbers are valid
        Ok(prev), Ok(first) -> {
          let num_str =
            int.to_float(prev + first)
            |> float.modulo(by: 10.0)
            |> result.unwrap(0.0)
            |> float.truncate
            |> int.to_string

          // continue checking with current number as previous
          check(
            rest_str,
            first |> int.to_string |> option.Some,
            result |> string.append(num_str),
          )
        }

        // either number is invalid
        Error(Nil), Error(Nil) | Error(Nil), Ok(_first) | Ok(_prev), Error(Nil) -> {
          // just continue without operation
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

// T(n) = O(n + (n - 1) + ... + 2) = O(n^2) where n is length of string
// S(n) = O(n)
fn t(s: String) {
  operate(s)
}

pub fn run() {
  let s1 = "3902"
  // true
  echo t(s1)

  let s2 = "34789"
  // false
  echo t(s2)

  let s3 = "1234567890"
  // true
  echo t(s3)
}
