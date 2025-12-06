import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_6b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_6b_sample", fn() {
    assert main("puzzle_inputs/day_6b_sample") == 3_263_827
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_6b", fn() {
    assert main("puzzle_inputs/day_6b") == 7_858_808_482_092
  })
}
