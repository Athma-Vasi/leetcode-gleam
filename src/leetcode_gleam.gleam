import gleam/int
import gleam/io
import graph/find_the_town_judge_997

pub fn main() {
  find_the_town_judge_997.run() |> int.to_string |> io.println
}
