import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_2a.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_2a_sample", fn() {
    assert main("puzzle_inputs/day_2a_sample") == 1_227_775_554
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_2a", fn() {
    assert main("puzzle_inputs/day_2a") == 18_595_663_903
  })
}
