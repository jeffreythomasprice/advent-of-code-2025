import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import utils

type Line {
  Left(Int)
  Right(Int)
}

pub fn main(filename: String) -> Int {
  let assert Ok(lines) = parse_puzzle(filename)
  let #(_, result) =
    lines
    |> list.fold(#(50, 0), fn(current, line) {
      let #(current_value, total_times_on_target) = current
      let next = rotate(current_value, line)
      let next_times_on_target =
        case next == 0 {
          True -> 1
          False -> 0
        }
        + total_times_on_target
      #(next, next_times_on_target)
    })
  result
}

fn rotate(current: Int, input: Line) -> Int {
  let result = case input {
    Left(amount) -> current - amount
    Right(amount) -> current + amount
  }
  let result = result % 100
  case result < 0 {
    True -> result + 100
    False -> result
  }
}

fn parse_puzzle(filename: String) -> Result(List(Line), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )
  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  let assert Ok(r) =
    regexp.compile(
      "^([LR])([0-9]+)$",
      with: regexp.Options(case_insensitive: False, multi_line: False),
    )
  use lines <- result.try(
    utils.match_remaining_lines_regexp(lines, r, fn(match) {
      let regexp.Match(submatches:, ..) = match
      case submatches {
        [option.Some(direction), option.Some(amount)] -> {
          case direction, int.parse(amount) {
            "L", Ok(amount) -> Ok(Left(amount))
            "R", Ok(amount) -> Ok(Right(amount))
            _, _ -> Error("bad inputs")
          }
        }
        _ -> Error("bad match")
      }
    })
    |> result.map_error(string.inspect),
  )
  Ok(lines)
}
