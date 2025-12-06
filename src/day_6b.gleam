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

  use #(number_lines, remainder) <- result.try(
    lines
    |> utils.match_lines_regexp_until(number_line_regexp, fn(line) {
      let regexp.Match(content: line, ..) = line
      line
      |> string.to_graphemes
      |> list.map(fn(c) {
        case c {
          "0" -> Ok(option.Some(0))
          "1" -> Ok(option.Some(1))
          "2" -> Ok(option.Some(2))
          "3" -> Ok(option.Some(3))
          "4" -> Ok(option.Some(4))
          "5" -> Ok(option.Some(5))
          "6" -> Ok(option.Some(6))
          "7" -> Ok(option.Some(7))
          "8" -> Ok(option.Some(8))
          "9" -> Ok(option.Some(9))
          " " | "\t" | "\r" | "\n" -> Ok(option.None)
          _ -> Error("unexpected char: " <> c)
        }
      })
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
    |> string.to_graphemes
    |> list.map(fn(x) {
      case x {
        "+" -> Ok(option.Some(Add))
        "*" -> Ok(option.Some(Multiply))
        " " | "\t" | "\r" | "\n" -> Ok(option.None)
        _ -> Error("unrecognized operator: " <> x)
      }
    })
    |> utils.list_of_results_to_result,
  )

  let utils.Grid(width:, height:, ..) = number_lines
  assert width == list.length(operators)

  let operators_and_indices =
    operators
    |> list.index_map(fn(operator, i) {
      case operator {
        option.Some(operator) -> option.Some(#(operator, i))
        _ -> option.None
      }
    })
    |> list.filter_map(fn(x) {
      case x {
        option.None -> Error(Nil)
        option.Some(x) -> Ok(x)
      }
    })

  Ok(
    adjacent_pairs(list.append(operators_and_indices, [#(Add, width)]))
    |> list.map(fn(x) {
      let #(#(operator, start_index), #(_, end_index)) = x
      let end_index = end_index - 1
      let numbers =
        utils.iterate_integers(end_index, step: -1, end: start_index)
        |> list.map(fn(x) {
          utils.iterate_integers(0, step: 1, end: height - 1)
          |> list.map(fn(y) { utils.grid_get_at(number_lines, x, y) })
          |> list.filter_map(fn(value) {
            case value {
              option.Some(option.Some(value)) -> Ok(value)
              _ -> Error(Nil)
            }
          })
        })
        |> list.filter_map(fn(number) {
          case
            number
            |> list.reverse
            |> list.fold(#(1, 0), fn(x, value) {
              let #(base, sum) = x
              #(base * 10, value * base + sum)
            })
          {
            #(_, 0) -> Error(Nil)
            #(_, x) -> Ok(x)
          }
        })
      #(operator, numbers)
    }),
  )
}

fn adjacent_pairs(list: List(a)) -> List(#(a, a)) {
  case list {
    [] | [_] -> []
    [a, b] -> [#(a, b)]
    [a, b, ..tail] -> [#(a, b), ..adjacent_pairs([b, ..tail])]
  }
}
