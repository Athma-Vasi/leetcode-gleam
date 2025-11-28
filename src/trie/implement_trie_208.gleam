import gleam/dict
import gleam/string

pub type TrieNode {
  TrieNode(descendants: dict.Dict(String, TrieNode), is_end_of_word: Bool)
}

// Insert: O(L) time, O(L) space when creating a new path
// - L = number of graphemes in the word
// - Each step does a dict lookup/insert; assumed average O(1)
// - Space adds up only when new nodes are created (worst-case a fresh branch)
fn insert_helper(graphemes: List(String), curr_trie_node: TrieNode) -> TrieNode {
  case graphemes {
    [] -> {
      // Mark end of word and return updated node
      TrieNode(..curr_trie_node, is_end_of_word: True)
    }
    [grapheme, ..rest] -> {
      case curr_trie_node.descendants |> dict.get(grapheme) {
        Ok(descendant) -> {
          // Update the existing child and re-insert into descendants
          let updated_child = insert_helper(rest, descendant)
          let new_descendants =
            curr_trie_node.descendants |> dict.insert(grapheme, updated_child)
          TrieNode(
            descendants: new_descendants,
            is_end_of_word: curr_trie_node.is_end_of_word,
          )
        }

        Error(_) -> {
          // make new node
          let new_node =
            TrieNode(descendants: dict.new(), is_end_of_word: False)
          // build the new child by inserting the rest of graphemes
          let built_child = insert_helper(rest, new_node)
          // attach to ancestor (immutably) and return updated current node
          let new_descendants =
            curr_trie_node.descendants |> dict.insert(grapheme, built_child)
          TrieNode(
            descendants: new_descendants,
            is_end_of_word: curr_trie_node.is_end_of_word,
          )
        }
      }
    }
  }
}

fn insert(word: String, root: TrieNode) -> TrieNode {
  insert_helper(string.to_graphemes(word), root)
}

// Search: O(L) time, O(1) auxiliary space (recursion depth O(L))
fn search_go(graphemes: List(String), node: TrieNode) -> Bool {
  case graphemes {
    [] -> node.is_end_of_word
    [g, ..rest] -> {
      case node.descendants |> dict.get(g) {
        Ok(next) -> search_go(rest, next)
        Error(_) -> False
      }
    }
  }
}

// Returns True if the exact word exists in the trie
fn search(word: String, root: TrieNode) -> Bool {
  search_go(string.to_graphemes(word), root)
}

// Starts-with: O(L) time, O(1) auxiliary space (recursion depth O(L))
fn starts_with_go(graphemes: List(String), node: TrieNode) -> Bool {
  case graphemes {
    [] -> True
    [g, ..rest] -> {
      case node.descendants |> dict.get(g) {
        Ok(next) -> starts_with_go(rest, next)
        Error(_) -> False
      }
    }
  }
}

// Returns True if there is any word that starts with the given prefix
fn starts_with(prefix: String, root: TrieNode) -> Bool {
  starts_with_go(string.to_graphemes(prefix), root)
}

pub fn run() {
  let w1 = "app"
  let root = TrieNode(descendants: dict.new(), is_end_of_word: False)
  let root2 = insert(w1, root)
  echo search("app", root2)
  echo search("ap", root2)
  echo starts_with("ap", root2)
}
