import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_3b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_3b_sample", fn() {
    assert main("puzzle_inputs/day_3b_sample") == 3_121_910_778_619
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_3b", fn() {
    assert main("puzzle_inputs/day_3b") == 168_798_209_663_590
  })
}
