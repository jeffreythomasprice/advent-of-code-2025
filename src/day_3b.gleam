import gleam/int
import gleam/list
import gleam/result
import gleam/string
import utils

pub fn main(filename: String) -> Int {
  let assert Ok(lines) = parse_puzzle(filename)
  let results =
    lines
    |> list.map(fn(bank) {
      solve_bank(bank, 12)
      |> decimal_digits_to_int
    })
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

fn solve_bank(bank: List(Int), remaining_digits: Int) -> List(Int) {
  case remaining_digits {
    x if x <= 1 -> {
      let assert Ok(result) =
        bank
        |> list.reduce(int.max)
      [result]
    }
    _ -> {
      let #(first_digit, first_digit_index) =
        bank
        |> list.take(list.length(bank) - remaining_digits + 1)
        |> list.index_fold(#(0, -1), fn(acc, x, i) {
          let #(acc_x, _) = acc
          case x > acc_x {
            True -> #(x, i)
            False -> acc
          }
        })

      let remaining_digits =
        solve_bank(
          bank |> list.drop(first_digit_index + 1),
          remaining_digits - 1,
        )
      [first_digit, ..remaining_digits]
    }
  }
}

fn decimal_digits_to_int(digits: List(Int)) -> Int {
  case digits {
    [] -> 0
    [single] -> single
    [next, ..remainder] ->
      next
      * integer_power(10, list.length(remainder))
      + decimal_digits_to_int(remainder)
  }
}

fn integer_power(base: Int, power: Int) -> Int {
  case power {
    0 | 1 -> base
    _ -> base * integer_power(base, power - 1)
  }
}
