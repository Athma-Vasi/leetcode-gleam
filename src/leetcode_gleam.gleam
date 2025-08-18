import find_if_path_exists_in_graph_1971
import gleam/bool
import gleam/io

pub fn main() {
  find_if_path_exists_in_graph_1971.run() |> bool.to_string |> io.println
}
