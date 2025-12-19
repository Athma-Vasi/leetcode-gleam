import gleam/list

type Fix {
  Prefix
  Postfix
}

fn create_fixes_array(kind: Fix, nums: List(Int)) {
  case kind {
    Postfix -> {
      // Exclusive postfix products: product of elements to the right of index i
      let #(_, rev) =
        nums
        |> list.fold_right(from: #(1, []), with: fn(acc, num) {
          let #(prev_product, arr) = acc
          #(prev_product * num, arr |> list.append([prev_product]))
        })
      rev |> list.reverse()
    }

    Prefix -> {
      // Exclusive prefix products: product of elements to the left of index i
      let #(_, prefix_products_array) =
        nums
        |> list.fold(from: #(1, []), with: fn(acc, num) {
          let #(prev_product, arr) = acc
          #(prev_product * num, arr |> list.append([prev_product]))
        })
      prefix_products_array
    }
  }
}

fn calculate_products(
  products_array: List(Int),
  prefix_products_array: List(Int),
  postfix_products_array: List(Int),
) {
  case prefix_products_array, postfix_products_array {
    [], _ | _, [] -> products_array

    [prefix_product, ..rest_prefixes], [postfix_product, ..rest_postfixes] ->
      calculate_products(
        products_array |> list.append([prefix_product * postfix_product]),
        rest_prefixes,
        rest_postfixes,
      )
  }
}

// T(n) = O(n)
// S(n) = O(n)
fn t(nums: List(Int)) {
  let prefix_products_array = create_fixes_array(Prefix, nums)
  let postfix_products_array = create_fixes_array(Postfix, nums)
  calculate_products([], prefix_products_array, postfix_products_array)
}

pub fn run() {
  let n1 = [1, 2, 3, 4]
  // [24, 12, 8, 6]
  echo t(n1)

  let n2 = [-1, 1, 0, -3, 3]
  //  [0, 0, 9, 0, 0]
  echo t(n2)
}
