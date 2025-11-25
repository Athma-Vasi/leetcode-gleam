fn find_smallest(k: Int, length: Int, remainder: Int) {
  // Calculate the new remainder by adding another '1'
  let new_remainder = { remainder * 10 + 1 } % k

  // Check if this repunit is divisible by k
  case new_remainder == 0 {
    True -> length
    False -> {
      // Check if we've exceeded the bound
      case length >= k {
        True -> -1
        False -> find_smallest(k, length + 1, new_remainder)
      }
    }
  }
}

// T(n, k) = O(k)
// S(n, k) = O(1)
fn t(k: Int) {
  find_smallest(k, 1, 0)
}

pub fn run() {
  let k1 = 1
  // 1
  echo t(k1)

  let k2 = 2
  // -1
  echo t(k2)

  let k3 = 3
  // 3
  echo t(k3)
}
