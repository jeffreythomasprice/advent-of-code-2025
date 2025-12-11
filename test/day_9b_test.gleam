import advent_of_code_2025_test.{run_if_test_is_enabled}
import day_9b.{main}

pub fn sample_test() {
  run_if_test_is_enabled("day_9b_sample", fn() {
    assert main("puzzle_inputs/day_9b_sample") == 24
  })
}

pub fn main_test() {
  run_if_test_is_enabled("day_9b", fn() {
    // TODO 4685325345 is too high
    assert main("puzzle_inputs/day_9b") == 4_685_325_345
  })
}
