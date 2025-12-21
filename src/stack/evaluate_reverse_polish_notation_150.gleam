import gleam/int
import gleam/list
import gleam/result

fn grab_two_operands(operand_stack: List(Int)) -> #(Int, Int, List(Int)) {
  // Pop two operands from the top of the stack (LIFO)
  operand_stack
  |> list.index_fold(from: #(0, 0, []), with: fn(acc, operand, index) {
    let #(operand1, operand2, rest_operands) = acc

    case index {
      0 -> #(operand1, operand, rest_operands)
      1 -> #(operand, operand2, rest_operands)
      _ -> #(operand1, operand2, [operand, ..rest_operands])
    }
  })
}

// T(n) = O(n)
// S(n) = O(n)
fn evaluate(result: Int, operand_stack: List(Int), tokens: List(String)) {
  case tokens {
    [] -> result

    [token, ..rest_tokens] -> {
      let #(operand1, operand2, rest_operands) =
        grab_two_operands(operand_stack)

      case token {
        "+" -> {
          let sum = operand1 + operand2
          evaluate(sum, [sum, ..rest_operands], rest_tokens)
        }
        "-" -> {
          let difference = operand1 - operand2
          evaluate(difference, [difference, ..rest_operands], rest_tokens)
        }
        "*" -> {
          let product = operand1 * operand2
          evaluate(product, [product, ..rest_operands], rest_tokens)
        }
        "/" -> {
          let quotient = operand1 / operand2
          evaluate(quotient, [quotient, ..rest_operands], rest_tokens)
        }
        char -> {
          // Operand token: parse and push onto the operand stack
          let operand = int.parse(char) |> result.unwrap(or: 0)
          evaluate(result, [operand, ..operand_stack], rest_tokens)
        }
      }
    }
  }
}

fn t(tokens: List(String)) {
  evaluate(0, [], tokens)
}

pub fn run() {
  let t1 = ["2", "1", "+", "3", "*"]
  // 9
  echo t(t1)

  let t2 = ["4", "13", "5", "/", "+"]
  // 6
  echo t(t2)

  let t3 = ["10", "6", "9", "3", "+", "-11", "*", "/", "*", "17", "+", "5", "+"]
  // 22
  echo t(t3)
}
