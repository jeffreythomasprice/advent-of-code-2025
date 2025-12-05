import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import utils

pub fn main(filename: String) -> Int {
  let assert Ok(#(ranges, ingredients)) = parse(filename)

  let ranges =
    ranges
    |> list.map(fn(r) {
      let #(left, right) = r
      new_range(left, right)
    })

  let assert Ok(bounds) =
    ranges
    |> list.reduce(fn(bounds, r) {
      let Range(left: bounds_left, right: bounds_right) = bounds
      let Range(left:, right:) = r
      Range(
        left: int.min(bounds_left, left),
        right: int.max(bounds_right, right),
      )
    })

  let Range(left:, right:) = bounds

  let buckets =
    ranges |> list.fold(new_buckets({ right - left } / 10), buckets_insert)

  ingredients
  |> list.filter(fn(i) { buckets_contains(buckets, i) })
  |> list.length
}

fn parse(filename: String) -> Result(#(List(#(Int, Int)), List(Int)), String) {
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
  use #(ranges, remainder) <- result.try(
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

  use ingredients <- result.try(
    remainder
    |> list.map(int.parse)
    |> utils.list_of_results_to_result
    |> result.map_error(fn(_) { "failed to map some line as an integer" }),
  )

  Ok(#(ranges, ingredients))
}

type Range {
  Range(left: Int, right: Int)
}

fn new_range(left: Int, right: Int) -> Range {
  Range(left: int.min(left, right), right: int.max(left, right))
}

fn range_contains(r: Range, x: Int) -> Bool {
  let Range(left:, right:) = r
  x >= left && x <= right
}

type Buckets {
  Buckets(scale: Int, buckets: dict.Dict(Int, List(Range)))
}

fn new_buckets(scale: Int) -> Buckets {
  Buckets(scale:, buckets: dict.new())
}

fn buckets_insert(b: Buckets, r: Range) -> Buckets {
  let Buckets(scale:, buckets:) = b
  let Range(left:, right:) = r
  let left_i = left / scale
  let right_i = right / scale
  let buckets =
    utils.iterate_integers(left_i, step: 1, end: right_i)
    |> list.fold(buckets, fn(buckets, i) {
      let bucket =
        dict.get(buckets, i)
        |> result.unwrap([])
      dict.insert(buckets, i, [r, ..bucket])
    })
  Buckets(scale:, buckets:)
}

fn buckets_contains(b: Buckets, x: Int) -> Bool {
  let Buckets(scale:, buckets:) = b
  dict.get(buckets, x / scale)
  |> result.unwrap([])
  |> list.any(fn(r) { range_contains(r, x) })
}
