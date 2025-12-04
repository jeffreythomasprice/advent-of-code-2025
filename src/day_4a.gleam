import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import utils

type Cell {
  Empty
  Box
}

type Puzzle {
  Puzzle(width: Int, height: Int, cells: List(Cell))
}

fn puzzle_get_at(p: Puzzle, x: Int, y: Int) -> option.Option(Cell) {
  let Puzzle(width:, height:, cells:) = p
  case x, y {
    x, y if x >= 0 && x < width && y >= 0 && y < height -> {
      case list.drop(cells, x + y * width) {
        [result, ..] -> option.Some(result)
        _ -> option.None
      }
    }
    _, _ -> option.None
  }
}

fn puzzle_count_neighbor_boxes(p: Puzzle, x: Int, y: Int) -> Int {
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
    case puzzle_get_at(p, neighbor_x, neighbor_y) {
      option.Some(Box) -> 1
      _ -> 0
    }
  })
  |> list.fold(0, fn(a, b) { a + b })
}

pub fn main(filename: String) -> Int {
  let assert Ok(p) = parse_puzzle(filename)

  let Puzzle(width:, height:, ..) = p

  let x_list = utils.iterate_integers(0, step: 1, end: width - 1)
  let y_list = utils.iterate_integers(0, step: 1, end: height - 1)

  x_list
  |> list.map(fn(x) {
    y_list
    |> list.map(fn(y) {
      case puzzle_get_at(p, x, y) {
        option.Some(Box) ->
          case puzzle_count_neighbor_boxes(p, x, y) {
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

fn parse_puzzle(filename: String) -> Result(Puzzle, String) {
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

  let height = list.length(data)
  use width <- result.try(
    case data |> list.map(list.length) |> set.from_list |> set.to_list {
      [width] -> Ok(width)
      _ -> Error("no lines or multiple lines of different lengths")
    },
  )

  Ok(Puzzle(width:, height:, cells: data |> list.flatten))
}
