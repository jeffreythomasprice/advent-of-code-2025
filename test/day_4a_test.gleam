import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_4a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_4a_sample", fn() {
    assert main("puzzle_inputs/day_4a_sample") == 13
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_4a", fn() {
    assert main("puzzle_inputs/day_4a") == 1457
  })
}
