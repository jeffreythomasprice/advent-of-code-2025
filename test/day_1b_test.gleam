import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_1b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_1b_sample", fn() {
    assert main("puzzle_inputs/day_1b_sample") == 6
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_1b", fn() {
    assert main("puzzle_inputs/day_1b") == 6770
  })
}
