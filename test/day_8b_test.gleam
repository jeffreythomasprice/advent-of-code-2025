import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_8b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_8b_sample", fn() {
    assert main("puzzle_inputs/day_8b_sample") == 25_272
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_8b", fn() {
    assert main("puzzle_inputs/day_8b") == 27_338_688
  })
}
