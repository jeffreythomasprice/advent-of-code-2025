import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_6a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_6a_sample", fn() {
    assert main("puzzle_inputs/day_6a_sample") == 4_277_556
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_6a", fn() {
    assert main("puzzle_inputs/day_6a") == 4_412_382_293_768
  })
}
