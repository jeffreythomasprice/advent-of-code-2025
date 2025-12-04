import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_4b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_4b_sample", fn() {
    assert main("puzzle_inputs/day_4b_sample") == 43
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_4b", fn() {
    assert main("puzzle_inputs/day_4b") == 8310
  })
}
