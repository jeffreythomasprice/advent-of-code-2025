import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_9a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_9a_sample", fn() {
    assert main("puzzle_inputs/day_9a_sample") == 50
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_9a", fn() {
    assert main("puzzle_inputs/day_9a") == 4_758_598_740
  })
}
