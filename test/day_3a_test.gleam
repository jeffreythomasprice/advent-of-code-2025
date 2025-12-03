import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_3a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_3a_sample", fn() {
    assert main("puzzle_inputs/day_3a_sample") == 357
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_3a", fn() {
    assert main("puzzle_inputs/day_3a") == 17_034
  })
}
