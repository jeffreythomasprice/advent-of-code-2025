import gleam/int
import gleam/list
import gleam/result
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
  let left_is_even = string.length(left) % 2 == 0
  let right_is_even = string.length(right) % 2 == 0

  case
    !left_is_even
    && !right_is_even
    && string.length(left) == string.length(right)
  {
    True -> {
      Ok(0)
    }

    False -> {
      let left_start = case string.length(left), left_is_even {
        1, _ -> "0"
        _, True -> left |> string.drop_end(string.length(left) / 2)
        _, False -> left |> string.drop_end(string.length(left) / 2 + 1)
      }
      let right_start = case string.length(right), right_is_even {
        1, _ -> "0"
        _, True -> right |> string.drop_end(string.length(right) / 2)
        _, False -> right |> string.drop_end(string.length(right) / 2)
      }

      use left_int <- result.try(
        int.parse(left)
        |> result.map_error(fn(_) { "left failed to parse as int: " <> left }),
      )
      use right_int <- result.try(
        int.parse(right)
        |> result.map_error(fn(_) { "right failed to parse as int: " <> right }),
      )
      use left_start_int <- result.try(
        int.parse(left_start)
        |> result.map_error(fn(_) {
          "left first half failed to parse as int: " <> left_start
        }),
      )
      use right_start_int <- result.try(
        int.parse(right_start)
        |> result.map_error(fn(_) {
          "right first half failed to parse as int: " <> right_start
        }),
      )

      use results <- result.try(
        utils.iterate_integers(left_start_int, step: 1, end: right_start_int)
        |> list.filter_map(fn(x) {
          let s = int.to_string(x)
          let s = s <> s
          use i <- result.try(int.parse(s))
          case i >= left_int && i <= right_int {
            True -> Ok(s)
            False -> Error(Nil)
          }
        })
        |> list.map(fn(x) {
          int.parse(x)
          |> result.map_error(fn(_) {
            "failed to parse possible result as int: " <> x
          })
        })
        |> utils.list_of_results_to_result,
      )

      Ok(
        results
        |> list.fold(0, fn(acc, x) { acc + x }),
      )
    }
  }
}
