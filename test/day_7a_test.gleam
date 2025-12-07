import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_7a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_7a_sample", fn() {
    assert main("puzzle_inputs/day_7a_sample") == 21
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_7a", fn() {
    assert main("puzzle_inputs/day_7a") == 1626
  })
}
