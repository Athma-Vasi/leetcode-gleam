fn gcd(a, b) {
  case b == 0 {
    True -> a
    False -> gcd(b, a % b)
  }
}

fn operation() {
  todo
}
