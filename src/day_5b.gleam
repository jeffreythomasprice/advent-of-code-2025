import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import utils

pub fn main(filename: String) -> Int {
  let assert Ok(ranges) = parse(filename)

  let ranges =
    ranges
    |> list.map(fn(r) {
      let #(left, right) = r
      new_range(left, right)
    })

  count_ranges(ranges)
}

fn parse(filename: String) -> Result(List(#(Int, Int)), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )

  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  use range_regexp <- result.try(
    regexp.compile(
      "^([0-9]+)-([0-9]+)$",
      regexp.Options(case_insensitive: False, multi_line: False),
    )
    |> result.map_error(fn(e) { string.inspect(e) }),
  )
  use #(ranges, _) <- result.try(
    lines
    |> utils.match_lines_regexp_until(range_regexp, fn(m) {
      case m {
        regexp.Match(submatches: [option.Some(a), option.Some(b)], ..) ->
          Ok(#(a, b))
        regexp.Match(content:, ..) -> Error("failed to match: " <> content)
      }
    })
    |> result.map_error(fn(e) { string.inspect(e) }),
  )
  use ranges <- result.try(
    ranges
    |> list.map(fn(r) {
      let #(a, b) = r
      case int.parse(a), int.parse(b) {
        Ok(a), Ok(b) -> Ok(#(a, b))
        _, _ ->
          Error(
            "at least one side of a range failed to parse as an integer: "
            <> a
            <> " - "
            <> b,
          )
      }
    })
    |> utils.list_of_results_to_result,
  )

  Ok(ranges)
}

type Range {
  Range(left: Int, right: Int)
}

fn new_range(left: Int, right: Int) -> Range {
  Range(left: int.min(left, right), right: int.max(left, right))
}

fn range_count(r: Range) -> Int {
  let Range(left:, right:) = r
  right - left + 1
}

fn range_subtract(r1: Range, r2: Range) -> List(Range) {
  case r1, r2 {
    // disjoint
    // r1 - r2 = r1
    Range(left1, right1), Range(left2, right2)
      if right1 < left2 || left1 > right2
    -> [r1]

    // r2 contains r1
    // r1 - r2 = nothing
    Range(left1, right1), Range(left2, right2)
      if left1 >= left2 && right1 <= right2
    -> []

    // r1 contains r2
    // r1 - r2 = two segments on either end
    Range(left1, right1), Range(left2, right2)
      if left2 >= left1 && right2 <= right1
    -> [
      Range(left: left1, right: left2 - 1),
      Range(left: right2 + 1, right: right1),
    ]

    // r1 contains the left edge of r2
    // r1 - r2 = the left side of r1
    Range(left1, right1), Range(left2, _) if left2 >= left1 && left2 <= right1 -> [
      Range(left: left1, right: left2 - 1),
    ]

    // r1 contains the right edge of r2
    // r1 - r2 = the right side of r1
    Range(_, right1), Range(_, right2) -> [
      Range(left: right2 + 1, right: right1),
    ]
  }
}

fn range_subtract_all(r: Range, others: List(Range)) -> List(Range) {
  case others {
    [] -> [r]
    [other] -> range_subtract(r, other)
    [head, ..tail] ->
      range_subtract(r, head)
      |> list.flat_map(fn(other) { range_subtract_all(other, tail) })
  }
}

fn count_ranges(ranges: List(Range)) -> Int {
  case ranges {
    [] -> 0
    [r] -> range_count(r)
    [head, ..tail] -> {
      let head_count =
        range_subtract_all(head, tail)
        |> list.fold(0, fn(sum, r) { sum + range_count(r) })
      head_count + count_ranges(tail)
    }
  }
}
