import gleam/list
import gleam/option
import gleam/result
import gleam/string
import utils

type Cell {
  Start
  Splitter
  Empty
  Line
}

pub fn main(filename: String) -> Int {
  let assert Ok(puzzle) = parse(filename)
  let #(_, count) = solve(puzzle)
  count
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
          "S" -> Ok(Start)
          "^" -> Ok(Splitter)
          "." -> Ok(Empty)
          _ -> Error("unrecognized character: " <> c)
        }
      })
      |> utils.list_of_results_to_result
    })
    |> utils.list_of_results_to_result,
  )
  use result <- result.try(utils.new_grid(data))

  Ok(result)
}

fn solve_row(puzzle: utils.Grid(Cell), y: Int) -> #(utils.Grid(Cell), Int) {
  utils.grid_iterate_width(puzzle)
  |> list.fold(#(puzzle, 0), fn(puzzle_and_count, x) {
    let #(puzzle, count) = puzzle_and_count
    let #(new_value, new_count) = case
      // to our left on this row
      utils.grid_get_at(puzzle, x - 1, y),
      // to our left on the previous row
      utils.grid_get_at(puzzle, x - 1, y - 1),
      // above us on the previous row
      utils.grid_get_at(puzzle, x, y - 1),
      // to our right on the previous row
      utils.grid_get_at(puzzle, x + 1, y - 1),
      // to our right on this row
      utils.grid_get_at(puzzle, x + 1, y),
      // this value
      utils.grid_get_at(puzzle, x, y)
    {
      // hitting a spitter
      _, _, option.Some(Line), _, _, option.Some(Splitter) -> #(Splitter, 1)
      // splitter above
      _, _, option.Some(Start), _, _, option.Some(Empty) -> #(Line, 0)
      // active splitter to our left
      option.Some(Splitter), option.Some(Line), _, _, _, option.Some(Empty) -> #(
        Line,
        0,
      )
      // active splitter to our right
      _, _, _, option.Some(Line), option.Some(Splitter), option.Some(Empty) -> #(
        Line,
        0,
      )
      // line above
      _, _, option.Some(Line), _, _, option.Some(Empty) -> #(Line, 0)
      // anything else stays the same
      _, _, _, _, _, option.Some(value) -> #(value, 0)
      // out of bounds should be impossible
      _, _, _, _, _, option.None -> #(Empty, 0)
    }
    #(utils.grid_set_at(puzzle, x, y, new_value), count + new_count)
  })
}

fn solve(puzzle: utils.Grid(Cell)) -> #(utils.Grid(Cell), Int) {
  utils.grid_iterate_height(puzzle)
  |> list.fold(#(puzzle, 0), fn(puzzle_and_count, y) {
    let #(puzzle, count) = puzzle_and_count
    let #(puzzle, new_count) = solve_row(puzzle, y)
    #(puzzle, count + new_count)
  })
}
