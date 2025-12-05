import gleam/list
import gleam/option
import gleam/result
import gleam/string
import utils

type Cell {
  Empty
  Box
}

pub fn main(filename: String) -> Int {
  let assert Ok(g) = parse(filename)

  let utils.Grid(width:, height:, ..) = g

  let x_list = utils.iterate_integers(0, step: 1, end: width - 1)
  let y_list = utils.iterate_integers(0, step: 1, end: height - 1)

  x_list
  |> list.map(fn(x) {
    y_list
    |> list.map(fn(y) {
      case utils.grid_get_at(g, x, y) {
        option.Some(Box) ->
          case count_neighbor_boxes(g, x, y) {
            n if n < 4 -> 1
            _ -> 0
          }
        _ -> 0
      }
    })
  })
  |> list.flatten
  |> list.fold(0, fn(a, b) { a + b })
}

fn parse(filename: String) -> Result(utils.Grid(Cell), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )

  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  use data <- result.try(
    lines
    |> list.map(fn(line) {
      line
      |> string.to_graphemes
      |> list.map(fn(c) {
        case c {
          "." -> Ok(Empty)
          "@" -> Ok(Box)
          _ -> Error("unhandled char: " <> c)
        }
      })
      |> utils.list_of_results_to_result
    })
    |> utils.list_of_results_to_result,
  )

  utils.new_grid(data)
}

fn count_neighbor_boxes(g: utils.Grid(Cell), x: Int, y: Int) -> Int {
  [
    #(-1, -1),
    #(-1, 0),
    #(-1, 1),
    #(0, 1),
    #(1, 1),
    #(1, 0),
    #(1, -1),
    #(0, -1),
  ]
  |> list.map(fn(deltas) {
    let #(x_delta, y_delta) = deltas
    let neighbor_x = x + x_delta
    let neighbor_y = y + y_delta
    case utils.grid_get_at(g, neighbor_x, neighbor_y) {
      option.Some(Box) -> 1
      _ -> 0
    }
  })
  |> list.fold(0, fn(a, b) { a + b })
}
