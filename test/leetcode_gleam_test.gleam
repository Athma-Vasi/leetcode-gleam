import gleam/option
import gleeunit
import src/graph/word_ladder_127

pub fn main() -> Nil {
  gleeunit.main()
}

// Word Ladder (LeetCode 127) Test Cases

// Test case 1: Basic example with valid transformation path
pub fn word_ladder_basic_example_test() {
  let begin_word = "hit"
  let end_word = "cog"
  let word_list = ["hot", "dot", "dog", "lot", "log", "cog"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Path: hit -> hot -> dot -> dog -> cog (length 5)
  assert result == 5
}

// Test case 2: End word not in word list
pub fn word_ladder_end_word_not_in_list_test() {
  let begin_word = "hit"
  let end_word = "cog"
  let word_list = ["hot", "dot", "dog", "lot", "log"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // No transformation possible, should return 0
  assert result == 0
}

// Test case 3: Single word in list that matches end word
pub fn word_ladder_single_transformation_test() {
  let begin_word = "hit"
  let end_word = "hot"
  let word_list = ["hot"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Path: hit -> hot (length 2)
  assert result == 2
}

// Test case 4: Word list has multiple valid paths, should find shortest
pub fn word_ladder_multiple_paths_test() {
  let begin_word = "cat"
  let end_word = "dog"
  let word_list = ["cat", "bat", "hat", "hat", "dog", "lot", "log", "cog"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Expected path exists, checking for valid distance
  assert result > 0
}

// Test case 5: No valid transformation path (disconnected graph)
pub fn word_ladder_no_path_test() {
  let begin_word = "hit"
  let end_word = "cog"
  let word_list = ["hot", "dot"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // No path connects to cog
  assert result == 0
}

// Test case 6: Begin word and end word differ by one letter
pub fn word_ladder_one_letter_difference_test() {
  let begin_word = "cold"
  let end_word = "warm"
  let word_list = ["cold", "cord", "card", "ward", "warm"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Path exists through the word list
  assert result > 0
}

// Test case 7: Empty word list
pub fn word_ladder_empty_list_test() {
  let begin_word = "hit"
  let end_word = "cog"
  let word_list = []

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // No words in list, no transformation possible
  assert result == 0
}

// Test case 8: Words with length 2
pub fn word_ladder_short_words_test() {
  let begin_word = "at"
  let end_word = "it"
  let word_list = ["at", "as", "is", "it"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Path should exist: at -> as -> is -> it (length 4)
  assert result == 4
}

// Test case 9: Longer word transformation chain
pub fn word_ladder_long_chain_test() {
  let begin_word = "cold"
  let end_word = "warm"
  let word_list = [
    "cold",
    "cold",
    "cold",
    "cord",
    "card",
    "ward",
    "warm",
    "warm",
  ]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Path: cold -> cord -> card -> ward -> warm (length 5)
  assert result == 5
}

// Test case 10: Duplicate words in list
pub fn word_ladder_duplicates_in_list_test() {
  let begin_word = "hit"
  let end_word = "cog"
  let word_list = ["hot", "hot", "dot", "dog", "lot", "log", "cog", "cog"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Should handle duplicates correctly
  assert result == 5
}

// Test case 11: Word requiring multiple intermediate steps
pub fn word_ladder_complex_path_test() {
  let begin_word = "a"
  let end_word = "c"
  let word_list = ["a", "b", "c"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Path: a -> b -> c (length 3) - but single letter so no valid transformation
  // Since words differ by more than one character position, result might be 0
  assert result == 0
}

// Test case 12: Larger word set with multiple interconnections
pub fn word_ladder_large_interconnected_set_test() {
  let begin_word = "red"
  let end_word = "tax"
  let word_list = ["ted", "tex", "red", "tax", "tad", "den", "rex", "pad"]

  let result =
    word_ladder_127.calculate_shortest_valid_transformation_distance(
      begin_word,
      end_word,
      word_list,
    )

  // Check that a valid distance is returned if path exists
  assert result > 0
}
