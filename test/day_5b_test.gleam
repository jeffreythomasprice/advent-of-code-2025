import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_5b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_5b_sample", fn() {
    assert main("puzzle_inputs/day_5b_sample") == 14
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_5b", fn() {
    assert main("puzzle_inputs/day_5b") == 345_755_049_374_932
  })
}
