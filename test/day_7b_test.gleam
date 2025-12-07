import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_7b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_7b_sample", fn() {
    assert main("puzzle_inputs/day_7b_sample") == 40
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_7b", fn() {
    assert main("puzzle_inputs/day_7b") == 48_989_920_237_096
  })
}
