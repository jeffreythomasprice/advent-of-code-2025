import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_8a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_8a_sample", fn() {
    assert main("puzzle_inputs/day_8a_sample", 10, 3) == 40
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_8a", fn() {
    assert main("puzzle_inputs/day_8a", 1000, 3) == 123_930
  })
}
