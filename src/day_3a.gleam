import gleam/int
import gleam/list
import gleam/result
import gleam/string
import utils

pub fn main(filename: String) -> Int {
  let assert Ok(lines) = parse_puzzle(filename)
  let results = lines |> list.map(solve_bank)
  results |> list.fold(0, fn(a, b) { a + b })
}

fn parse_puzzle(filename: String) -> Result(List(List(Int)), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )
  use results <- result.try(
    lines
    |> list.filter(fn(line) { !string.is_empty(line) })
    |> list.map(string.to_graphemes)
    |> list.map(fn(x) {
      x
      |> list.map(int.parse)
      |> utils.list_of_results_to_result
    })
    |> utils.list_of_results_to_result
    |> result.map_error(fn(_) { "number parse error" }),
  )
  Ok(results)
}

fn solve_bank(bank: List(Int)) -> Int {
  let #(first_digit, first_digit_index) =
    bank
    |> list.take(list.length(bank) - 1)
    |> list.index_fold(#(0, -1), fn(acc, x, i) {
      let #(acc_x, _) = acc
      case x > acc_x {
        True -> #(x, i)
        False -> acc
      }
    })

  let assert Ok(second_digit) =
    bank
    |> list.drop(first_digit_index + 1)
    |> list.reduce(int.max)

  first_digit * 10 + second_digit
}
