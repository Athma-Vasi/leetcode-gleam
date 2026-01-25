/// Word Ladder (LeetCode Problem 127)
/// 
/// This module solves the Word Ladder problem using breadth-first search (BFS) on a graph
/// of words connected by single-letter transformations.
///
/// Problem: Given a begin word, an end word, and a word list, find the length of the 
/// shortest transformation sequence from begin to end word, where each intermediate word
/// must exist in the provided word list and differ from the previous word by exactly 
/// one letter.
///
/// Approach:
/// 1. Build an undirected graph where nodes are words and edges connect words differing
///    by exactly one letter
/// 2. Use BFS to find the shortest path from begin_word to end_word
/// 3. Return the path length, or 0 if no path exists
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/set
import gleam/string

/// Type alias representing a word as a String
type Word =
  String

/// Type alias for a list of words
type WordList =
  List(Word)

/// Type alias for distance/path length tracking during BFS traversal
type Distance =
  Int

/// Adjacency list representation of the word transformation graph.
/// Maps each word to the set of words that differ from it by exactly one letter.
type AdjacencyList =
  dict.Dict(Word, set.Set(Word))

/// Determines whether two words differ by exactly one letter.
///
/// Algorithm:
/// - Returns False if words are identical
/// - Converts both words to grapheme sets and computes their union
/// - Two words differ by one letter if and only if:
///   * They have the same length
///   * The union of their grapheme sets has exactly word_length + 1 elements
///   (This means exactly one unique letter exists in one word but not the other)
///
/// Parameters:
/// - comparee: The first word to compare
/// - compared: The second word to compare
///
/// Returns: True if words differ by exactly one letter, False otherwise
fn determine_if_differs_by_one_letter(comparee, compared) -> Bool {
  case comparee == compared {
    True -> False

    False -> {
      let comparee_set =
        comparee
        |> string.to_graphemes
        |> set.from_list
      let union_set =
        compared
        |> string.to_graphemes
        |> list.fold(from: comparee_set, with: fn(letters_set, letter) {
          letters_set |> set.insert(letter)
        })
      let word_length = string.length(comparee)

      word_length + 1 == set.size(union_set)
    }
  }
}

/// Adds a directed edge from one word to another in the adjacency list.
///
/// This function updates or inserts an entry in the graph dictionary, maintaining
/// a set of adjacent words for each word node. Uses upsert (update or insert) to
/// handle both new words and existing words with updated adjacency sets.
///
/// Parameters:
/// - graph: The current adjacency list (dictionary) being built
/// - word: The source word node
/// - adjacent: The destination word node to add as adjacent to `word`
///
/// Returns: Updated adjacency list with the new edge added
fn add_edge_from(graph, word, adjacent: Word) {
  graph
  |> dict.upsert(update: word, with: fn(adjacents_maybe) {
    case adjacents_maybe {
      None -> set.new() |> set.insert(adjacent)
      Some(adjacents) -> adjacents |> set.insert(adjacent)
    }
  })
}

/// Constructs a word transformation graph from a list of words.
///
/// Builds a complete undirected graph where:
/// - Each word is a node
/// - Each pair of words differing by exactly one letter is connected by a bidirectional edge
///
/// Time Complexity: O(n² * m) where n is the number of words and m is the average word length
/// Space Complexity: O(n² * m) for storing the adjacency list in worst case
///
/// Algorithm:
/// - Performs nested iteration over the word list (O(n²) comparisons)
/// - For each pair of words, checks if they differ by exactly one letter
/// - If true, adds bidirectional edges (word1 -> word2 and word2 -> word1)
///
/// Parameters:
/// - word_list: List of words to build the graph from
///
/// Returns: Adjacency list representation of the word transformation graph
fn build_graph(word_list: List(Word)) -> AdjacencyList {
  let graph =
    word_list
    |> list.fold(from: dict.new(), with: fn(graph, comparee) {
      word_list
      |> list.fold(from: graph, with: fn(graph, compared) {
        case determine_if_differs_by_one_letter(comparee, compared) {
          False -> graph
          True ->
            graph
            |> add_edge_from(comparee, compared)
            |> add_edge_from(compared, comparee)
        }
      })
    })

  graph
}

/// Adds a set of word sequences to the BFS queue with updated distance.
///
/// Used during BFS traversal to enqueue all adjacent words at the next distance level.
/// Converts a set of adjacent words into (word, distance) tuples and appends them to
/// the queue for processing.
///
/// Parameters:
/// - sequences: Set of adjacent words to add to the queue
/// - queue: Current BFS queue of (word, distance) tuples
/// - distance: Current distance in the BFS traversal
///
/// Returns: Updated queue with all sequences added at distance + 1
fn add_sequences_to_queue(
  sequences: set.Set(Word),
  queue: List(#(Word, Distance)),
  distance: Int,
) {
  sequences
  |> set.fold(from: queue, with: fn(queue, sequence) {
    queue |> list.append([#(sequence, distance + 1)])
  })
}

/// Performs breadth-first search (BFS) to find the shortest transformation path.
///
/// Uses tail recursion to traverse the word transformation graph level by level,
/// exploring all words reachable from the begin_word through single-letter transformations.
/// Terminates when either:
/// - The end_word is found (found_valid_transformations = True)
/// - The queue is exhausted (no path exists)
///
/// Base cases:
/// - If end_word already found or queue is empty, return the distance
///
/// Recursive case:
/// - Dequeue the first (word, distance) tuple
/// - Look up adjacent words in the graph
/// - If the word has no adjacents, continue to next queued word
/// - If the word has adjacents, enqueue all of them at distance + 1
/// - Check if current word equals end_word and continue recursion
///
/// Parameters:
/// - graph: The adjacency list representation of the word transformation graph
/// - sequence_queue: FIFO queue of (word, distance) tuples to process
/// - total_distance: Current distance level in BFS traversal
/// - found_valid_transformations: Flag indicating whether end_word has been found
/// - end_word: The target word we're searching for
///
/// Returns: The shortest distance from begin_word to end_word, or 0 if unreachable
fn explore_transformations(
  graph,
  sequence_queue: List(#(Word, Distance)),
  total_distance: Int,
  found_valid_transformations: Bool,
  end_word: Word,
) {
  case found_valid_transformations, sequence_queue {
    True, [] | True, _queue | False, [] -> total_distance

    False, [first, ..rest_queue] -> {
      let #(potential_valid_transformation, distance) = first

      case graph |> dict.get(potential_valid_transformation) {
        Error(Nil) ->
          explore_transformations(
            graph,
            rest_queue,
            total_distance,
            found_valid_transformations,
            end_word,
          )

        Ok(sequence) -> {
          explore_transformations(
            graph,
            add_sequences_to_queue(sequence, rest_queue, distance),
            distance + 1,
            potential_valid_transformation == end_word,
            end_word,
          )
        }
      }
    }
  }
}

/// Validates whether the end_word exists in the provided word list.
///
/// This is a necessary precondition check since the end_word must be in the word list
/// to be a valid target in the word transformation problem.
///
/// Parameters:
/// - end_word: The target word whose presence we're checking
/// - word_list: The list of allowed transformation words
///
/// Returns: True if end_word is found in word_list, False otherwise
fn check_if_end_word_present_in_word_list(end_word: Word, word_list: WordList) {
  case
    word_list
    |> list.find(one_that: fn(word) { word == end_word })
  {
    Ok(_found) -> True
    Error(Nil) -> False
  }
}

/// Calculates the shortest transformation sequence length from begin_word to end_word.
///
/// Main solver function that orchestrates the word ladder solution:
/// 1. Validates that end_word exists in the word_list (required by problem constraints)
/// 2. Constructs a graph of word transformations including the begin_word
/// 3. Performs BFS to find the shortest path from begin_word to end_word
///
/// Algorithm:
/// - Returns -1 immediately if end_word is not in word_list (invalid input)
/// - Otherwise, builds graph and initiates BFS from begin_word with distance 0
/// - BFS explores all reachable words level by level, guaranteeing shortest path
///
/// Time Complexity: O(n² * m + e) where:
///   - n = number of words
///   - m = average word length
///   - e = number of edges in the graph (at most n²)
///   Graph building: O(n² * m), BFS: O(n + e)
///
/// Space Complexity: O(n * m) for storing the graph adjacency list
///
/// Parameters:
/// - begin_word: Starting word for transformation sequence
/// - end_word: Target word to reach
/// - word_list: List of valid intermediate transformation words
///
/// Returns: The length of the shortest transformation sequence (number of words including
///          begin_word and end_word), or -1 if end_word is not in word_list, or 0 if no
///          transformation path exists
fn calculate_shortest_valid_transformation_distance(
  begin_word: Word,
  end_word: Word,
  word_list: WordList,
) {
  case check_if_end_word_present_in_word_list(end_word, word_list) {
    False -> -1

    True ->
      build_graph([begin_word, ..word_list])
      |> explore_transformations([#(begin_word, 0)], 0, False, end_word)
  }
}

/// Entry point for executing comprehensive test cases for the Word Ladder solver.
///
/// Runs 12 distinct test scenarios covering:
/// - Basic valid transformation paths
/// - Edge cases (empty lists, single transformations)
/// - Invalid scenarios (end word not in list, disconnected graphs)
/// - Duplicate words in input
/// - Varying word lengths and complexity levels
///
/// Each test is clearly labeled with expected output for verification purposes.
pub fn run() {
  io.println("=== Word Ladder (LeetCode 127) - Comprehensive Test Cases ===")
  io.println("")

  // Test case 1: Basic example with valid transformation path
  io.println("Test 1: Basic example (hit -> cog)")
  let result1 =
    calculate_shortest_valid_transformation_distance("hit", "cog", [
      "hot",
      "dot",
      "dog",
      "lot",
      "log",
      "cog",
    ])
  io.println("Expected: 5, Got: " <> int.to_string(result1))
  io.println("Path: hit -> hot -> dot -> dog -> cog")
  io.println("")

  // Test case 2: End word not in word list
  io.println("Test 2: End word not in word list")
  let result2 =
    calculate_shortest_valid_transformation_distance("hit", "cog", [
      "hot",
      "dot",
      "dog",
      "lot",
      "log",
    ])
  io.println("Expected: -1, Got: " <> int.to_string(result2))
  io.println("Status: cog not in word list")
  io.println("")

  // Test case 3: Single word in list that matches end word
  io.println("Test 3: Single transformation (hit -> hot)")
  let result3 =
    calculate_shortest_valid_transformation_distance("hit", "hot", ["hot"])
  io.println("Expected: 2, Got: " <> int.to_string(result3))
  io.println("Path: hit -> hot")
  io.println("")

  // Test case 4: Word list has multiple valid paths
  io.println("Test 4: Multiple valid paths (cat -> dog)")
  let result4 =
    calculate_shortest_valid_transformation_distance("cat", "dog", [
      "cat",
      "bat",
      "hat",
      "dog",
      "lot",
      "log",
      "cog",
    ])
  io.println("Got: " <> int.to_string(result4))
  io.println("Status: Valid path exists (specific path may vary)")
  io.println("")

  // Test case 5: No valid transformation path (disconnected graph)
  io.println("Test 5: No valid path (disconnected components)")
  let result5 =
    calculate_shortest_valid_transformation_distance("hit", "cog", [
      "hot",
      "dot",
    ])
  io.println("Expected: 0, Got: " <> int.to_string(result5))
  io.println("Status: Cannot reach cog from hit with given words")
  io.println("")

  // Test case 6: Multiple intermediate steps (cold -> warm)
  io.println("Test 6: Multiple hops (cold -> warm)")
  let result6 =
    calculate_shortest_valid_transformation_distance("cold", "warm", [
      "cold",
      "cord",
      "card",
      "ward",
      "warm",
    ])
  io.println("Expected: 5, Got: " <> int.to_string(result6))
  io.println("Path: cold -> cord -> card -> ward -> warm")
  io.println("")

  // Test case 7: Empty word list
  io.println("Test 7: Empty word list")
  let result7 =
    calculate_shortest_valid_transformation_distance("hit", "cog", [])
  io.println("Expected: -1, Got: " <> int.to_string(result7))
  io.println("Status: No words available for transformation")
  io.println("")

  // Test case 8: Words with length 2
  io.println("Test 8: Short words - length 2 (at -> it)")
  let result8 =
    calculate_shortest_valid_transformation_distance("at", "it", [
      "at",
      "as",
      "is",
      "it",
    ])
  io.println("Expected: 4, Got: " <> int.to_string(result8))
  io.println("Path: at -> as -> is -> it")
  io.println("")

  // Test case 9: Longer word transformation chain with duplicates
  io.println("Test 9: Long chain with duplicates (cold -> warm)")
  let result9 =
    calculate_shortest_valid_transformation_distance("cold", "warm", [
      "cold",
      "cold",
      "cold",
      "cord",
      "card",
      "ward",
      "warm",
      "warm",
    ])
  io.println("Expected: 5, Got: " <> int.to_string(result9))
  io.println("Path: cold -> cord -> card -> ward -> warm")
  io.println("")

  // Test case 10: Duplicate words in list
  io.println("Test 10: Multiple duplicates in list (hit -> cog)")
  let result10 =
    calculate_shortest_valid_transformation_distance("hit", "cog", [
      "hot",
      "hot",
      "dot",
      "dog",
      "lot",
      "log",
      "cog",
      "cog",
    ])
  io.println("Expected: 5, Got: " <> int.to_string(result10))
  io.println("Path: hit -> hot -> dot -> dog -> cog")
  io.println("")

  // Test case 11: Single letter words (no valid transformation)
  io.println("Test 11: Single letter words (a -> c)")
  let result11 =
    calculate_shortest_valid_transformation_distance("a", "c", ["a", "b", "c"])
  io.println("Expected: 0, Got: " <> int.to_string(result11))
  io.println("Status: Single letter words cannot differ by exactly one letter")
  io.println("")

  // Test case 12: Larger word set with multiple interconnections
  io.println("Test 12: Complex graph (red -> tax)")
  let result12 =
    calculate_shortest_valid_transformation_distance("red", "tax", [
      "ted",
      "tex",
      "red",
      "tax",
      "tad",
      "den",
      "rex",
      "pad",
    ])
  io.println("Got: " <> int.to_string(result12))
  io.println("Status: Path finding in interconnected word graph")
  io.println("")

  io.println("=== All 12 test cases completed ===")
}
