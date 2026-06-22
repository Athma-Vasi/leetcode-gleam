import gleam/dict
import gleam/float
import gleam/int
import gleam/result

type ClockHour =
  Int

type ClockMinute =
  Float

type TimeKey =
  #(ClockHour, ClockMinute)

type Degrees =
  Float

/// Builds lookup table mapping hours (0-11) to their angles on a clock.
/// Each hour represents 30° (360 / 12).
/// Time: O(12) | Space: O(12)
fn build_hour_angles_table(
  hour: Int,
  angle: Float,
  table: dict.Dict(Int, Float),
) {
  case hour >= 12 {
    True -> table

    // Base case: all 12 hours processed
    False -> {
      // Increment hour and angle (30° per hour)
      let next_hour = hour + 1
      let next_angle = angle +. 30.0

      // Recurse with accumulated table
      build_hour_angles_table(
        next_hour,
        next_angle,
        table
          |> dict.insert(for: next_hour, insert: next_angle),
      )
    }
  }
}

/// Builds lookup table mapping (hour, minute) pairs to the smallest angle between clock hands.
/// Minute hand: 6° per minute. Hour hand: 30° per hour + 0.5° per minute.
/// Time: O(12 × 60) = O(720) | Space: O(720)
fn build_time_to_angle_table(
  hour_angles_table: dict.Dict(ClockHour, Degrees),
  hour: Int,
  minute: Float,
  time_to_angle_table: dict.Dict(TimeKey, Degrees),
) {
  case hour > 12, minute >=. 59.0 {
    // Base case: all hours completed (12 * 60 entries)
    True, _ -> time_to_angle_table

    // Move to next hour, reset minute to 0
    _, True ->
      build_time_to_angle_table(
        hour_angles_table,
        hour + 1,
        0.0,
        time_to_angle_table,
      )

    // Calculate angles for current (hour, minute) pair
    False, False -> {
      let next_minute = minute +. 1.0
      // Minute hand: 6° per minute (360° / 60 min)
      let minute_hand_angle = next_minute *. 6.0
      // Get base angle for current hour
      let hour_hand_start_angle =
        hour_angles_table |> dict.get(hour) |> result.unwrap(or: 0.0)
      // Hour hand moves 0.5° per minute (30° ÷ 60 min)
      let clockwise_difference =
        float.absolute_value(
          minute_hand_angle -. hour_hand_start_angle -. { next_minute /. 2.0 },
        )
      // Counter-clockwise angle: 360° - clockwise
      let counter_clockwise_difference = 360.0 -. clockwise_difference
      // Smallest angle between the two hands
      let smallest_angle =
        float.min(clockwise_difference, counter_clockwise_difference)

      // Store result and recurse
      build_time_to_angle_table(
        hour_angles_table,
        hour,
        next_minute,
        time_to_angle_table
          |> dict.insert(for: #(hour, next_minute), insert: smallest_angle),
      )
    }
  }
}

/// Calculates the smallest angle between hour and minute hands at a given time.
/// Uses precomputed tables for O(1) lookup. Time: O(1) | Space: O(1) amortized
fn calculate_angle(hour: Int, minute: Float) {
  // Build hour angles and pipe to time angle table builder
  let time_to_angle_table =
    build_hour_angles_table(0, 0.0, dict.new())
    |> build_time_to_angle_table(0, 0.0, dict.new())
  // Look up precomputed angle for (hour, minute), default to -1.0 if not found
  time_to_angle_table |> dict.get(#(hour, minute)) |> result.unwrap(or: -1.0)
}

/// Entry point for solution (precomputed lookup approach).
pub fn run() {
  // Test case 1: 12:30 → expected 165°
  let h1 = 12
  let m1 = 30
  echo calculate_angle(h1, m1 |> int.to_float)

  // Test case 2: 3:30 → expected 75°
  let h2 = 3
  let m2 = 30
  echo calculate_angle(h2, m2 |> int.to_float)

  // Test case 3: 3:15 → expected 7.5°
  let h3 = 3
  let m3 = 15
  echo calculate_angle(h3, m3 |> int.to_float)
}
