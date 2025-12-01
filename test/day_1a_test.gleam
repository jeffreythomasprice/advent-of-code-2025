import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_1a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_1a_sample", fn() {
    assert main("puzzle_inputs/day_1a_sample") == 3
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_1a", fn() {
    assert main("puzzle_inputs/day_1a") == 1195
  })
}
