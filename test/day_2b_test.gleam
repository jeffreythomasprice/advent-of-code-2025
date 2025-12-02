import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_2b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_2b_sample", fn() {
    assert main("puzzle_inputs/day_2b_sample") == 4_174_379_265
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_2b", fn() {
    assert main("puzzle_inputs/day_2b") == 19_058_204_438
  })
}
