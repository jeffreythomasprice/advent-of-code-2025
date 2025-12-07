import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import utils

type Operator {
  Add
  Multiply
}

pub fn main(filename: String) -> Int {
  let assert Ok(sequences) = parse(filename)

  let assert Ok(results) =
    sequences
    |> list.map(fn(s) {
      let #(operator, numbers) = s
      let operator = case operator {
        Add -> fn(a, b) { a + b }
        Multiply -> fn(a, b) { a * b }
      }
      list.reduce(numbers, operator)
    })
    |> utils.list_of_results_to_result

  results |> list.fold(0, fn(a, b) { a + b })
}

fn parse(filename: String) -> Result(List(#(Operator, List(Int))), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )

  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  let assert Ok(number_line_regexp) =
    regexp.from_string("^\\s*[0-9]+(?:\\s+[0-9]+)*\\s*$")
  let assert Ok(whitespace_regexp) = regexp.from_string("\\s+")

  use #(number_lines, remainder) <- result.try(
    lines
    |> utils.match_lines_regexp_until(number_line_regexp, fn(line) {
      let regexp.Match(content: line, ..) = line
      line
      |> regexp.split(with: whitespace_regexp)
      |> list.filter(fn(x) { !string.is_empty(x) })
      |> list.map(int.parse)
      |> utils.list_of_results_to_result
    })
    |> result.map_error(string.inspect),
  )
  use number_lines <- result.try(utils.new_grid(number_lines))

  use operator_line <- result.try(case remainder {
    [operator_line] -> Ok(operator_line)
    [] -> Error("no operator line")
    _ -> Error("multiple remaining lines")
  })
  use operators <- result.try(
    operator_line
    |> regexp.split(with: whitespace_regexp)
    |> list.filter(fn(x) { !string.is_empty(x) })
    |> list.map(fn(x) {
      case x {
        "+" -> Ok(Add)
        "*" -> Ok(Multiply)
        _ -> Error("unrecognized operator: " <> x)
      }
    })
    |> utils.list_of_results_to_result,
  )

  let utils.Grid(width:, ..) = number_lines
  assert width == list.length(operators)

  operators
  |> list.index_map(fn(operator, x) {
    utils.grid_iterate_height(number_lines)
    |> list.map(fn(y) {
      case utils.grid_get_at(number_lines, x, y) {
        option.Some(result) -> Ok(result)
        option.None -> Error("failed to get value from grid")
      }
    })
    |> utils.list_of_results_to_result
    |> result.map(fn(numbers) { #(operator, numbers) })
  })
  |> utils.list_of_results_to_result
}
