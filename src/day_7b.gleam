import gleam/list
import gleam/option
import gleam/result
import gleam/string
import utils

type Cell {
  Start
  Splitter
  Empty
  Line(Int)
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

fn solve_row(puzzle: utils.Grid(Cell), y: Int) -> utils.Grid(Cell) {
  utils.grid_iterate_width(puzzle)
  |> list.fold(puzzle, fn(puzzle, x) {
    let new_value = case
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
      _, _, option.Some(Line(_)), _, _, option.Some(Splitter) -> Splitter
      // start above
      _, _, option.Some(Start), _, _, option.Some(Empty) -> Line(1)
      // active splitter to both our left and right, and a third line above
      option.Some(Splitter),
        option.Some(Line(left)),
        option.Some(Line(above)),
        option.Some(Line(right)),
        option.Some(Splitter),
        option.Some(Empty)
      -> Line(left + right + above)
      // active splitter to both our left and right
      option.Some(Splitter),
        option.Some(Line(left)),
        _,
        option.Some(Line(right)),
        option.Some(Splitter),
        option.Some(Empty)
      -> Line(left + right)
      // active splitter to our left, and another line above
      option.Some(Splitter),
        option.Some(Line(left)),
        option.Some(Line(above)),
        _,
        _,
        option.Some(Empty)
      -> Line(left + above)
      // active splitter to our left
      option.Some(Splitter),
        option.Some(Line(left)),
        _,
        _,
        _,
        option.Some(Empty)
      -> Line(left)
      // active splitter to our right, and another line above
      _,
        _,
        option.Some(Line(above)),
        option.Some(Line(right)),
        option.Some(Splitter),
        option.Some(Empty)
      -> Line(right + above)
      // active splitter to our right
      _,
        _,
        _,
        option.Some(Line(right)),
        option.Some(Splitter),
        option.Some(Empty)
      -> Line(right)
      // line above
      _, _, option.Some(Line(above)), _, _, option.Some(Empty) -> Line(above)
      // anything else stays the same
      _, _, _, _, _, option.Some(value) -> value
      // out of bounds should be impossible
      _, _, _, _, _, option.None -> Empty
    }
    utils.grid_set_at(puzzle, x, y, new_value)
  })
}

fn solve(puzzle: utils.Grid(Cell)) -> #(utils.Grid(Cell), Int) {
  let puzzle =
    utils.grid_iterate_height(puzzle)
    |> list.fold(puzzle, fn(puzzle, y) { solve_row(puzzle, y) })

  let result =
    utils.grid_iterate_width(puzzle)
    |> list.map(fn(x) {
      case utils.grid_get_at(puzzle, x, utils.grid_height(puzzle) - 1) {
        option.Some(Line(x)) -> x
        _ -> 0
      }
    })
    |> list.fold(0, fn(a, b) { a + b })

  #(puzzle, result)
}
