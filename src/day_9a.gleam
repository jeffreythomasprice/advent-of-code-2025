import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import utils

pub fn main(filename: String) -> Int {
  let assert Ok(vertices) = parse(filename)
  find_largest_rectangle(vertices)
}

fn parse(filename: String) -> Result(List(#(Int, Int)), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )

  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  use r <- result.try(
    regexp.from_string("^([0-9]+),([0-9]+)$")
    |> result.map_error(string.inspect),
  )

  lines
  |> utils.match_remaining_lines_regexp(r, fn(m) {
    let regexp.Match(submatches:, ..) = m
    case submatches {
      [option.Some(x), option.Some(y)] -> {
        use x <- result.try(
          int.parse(x) |> result.map_error(fn(_) { "failed to match x: " <> x }),
        )
        use y <- result.try(
          int.parse(y) |> result.map_error(fn(_) { "failed to match y: " <> y }),
        )
        Ok(#(x, y))
      }
      _ -> Error("failed to parse match: " <> string.inspect(m))
    }
  })
  |> result.map_error(string.inspect)
}

fn find_largest_rectangle(vertices: List(#(Int, Int))) -> Int {
  case vertices {
    [] | [_] -> 0
    [head, ..tail] ->
      int.max(
        tail |> list.map(fn(b) { area(head, b) }) |> list.fold(0, int.max),
        find_largest_rectangle(tail),
      )
  }
}

fn area(a: #(Int, Int), b: #(Int, Int)) -> Int {
  let #(ax, ay) = a
  let #(bx, by) = b
  let xd = int.absolute_value(ax - bx) + 1
  let yd = int.absolute_value(ay - by) + 1
  xd * yd
}
