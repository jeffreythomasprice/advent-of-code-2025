import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import utils

pub fn main(filename: String) -> Int {
  let assert Ok(lines) = parse_puzzle(filename)
  let assert Ok(results) =
    lines
    |> list.map(fn(x) {
      let #(left, right) = x
      handle(left, right)
    })
    |> utils.list_of_results_to_result
  results
  |> list.fold(0, fn(acc, x) { acc + x })
}

fn parse_puzzle(filename: String) -> Result(List(#(String, String)), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )
  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })
  use line <- result.try(case lines {
    [line] -> Ok(line)
    [] -> Error("no input")
    _ -> Error("multiple lines of input")
  })
  use parts <- result.try(
    line
    |> string.split(",")
    |> list.map(fn(x) {
      let parts = x |> string.split("-")
      case parts {
        [a, b] -> Ok(#(a, b))
        _ -> Error("didn't get exactly one part: " <> x)
      }
    })
    |> utils.list_of_results_to_result,
  )
  Ok(parts)
}

fn handle(left: String, right: String) -> Result(Int, String) {
  use left_int <- result.try(
    int.parse(left)
    |> result.map_error(fn(_) { "left failed to parse as int: " <> left }),
  )
  use right_int <- result.try(
    int.parse(right)
    |> result.map_error(fn(_) { "right failed to parse as int: " <> right }),
  )

  let max_str_length = int.max(string.length(left), string.length(right))
  let possible_prefix_length =
    utils.iterate_integers(1, step: 1, end: max_str_length / 2 + 1)

  Ok(
    utils.iterate_integers(left_int, step: 1, end: right_int)
    |> list.map(fn(i) {
      let s = i |> int.to_string
      possible_prefix_length
      |> list.filter_map(fn(prefix_length) {
        let repeats = string.length(s) / prefix_length
        let possible =
          string.drop_end(s, up_to: string.length(s) - prefix_length)
          |> string.repeat(repeats)
        case repeats >= 2 && possible == s {
          True -> {
            Ok(possible)
          }
          False -> Error(Nil)
        }
      })
    })
    |> list.flatten
    |> set.from_list
    |> set.to_list
    |> list.filter_map(fn(s) {
      use i <- result.try(s |> int.parse)
      Ok(i)
    })
    |> list.fold(0, fn(acc, x) { acc + x }),
  )
}
