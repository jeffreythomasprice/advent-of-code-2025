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
  let assert Ok(p) = parse(filename)
  remove_boxes_until_we_cant(p)
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

fn find_places_we_can_remove_a_box(g: utils.Grid(Cell)) -> List(#(Int, Int)) {
  utils.grid_iterate_width(g)
  |> list.map(fn(x) {
    utils.grid_iterate_height(g)
    |> list.map(fn(y) {
      case utils.grid_get_at(g, x, y) {
        option.Some(Box) ->
          case count_neighbor_boxes(g, x, y) {
            n if n < 4 -> option.Some(#(x, y))
            _ -> option.None
          }
        _ -> option.None
      }
    })
  })
  |> list.flatten
  |> list.filter_map(fn(x) {
    case x {
      option.Some(x) -> Ok(x)
      option.None -> Error(Nil)
    }
  })
}

fn remove_boxes_until_we_cant(g: utils.Grid(Cell)) -> Int {
  case find_places_we_can_remove_a_box(g) {
    [] -> 0
    places_we_can_remove_a_box -> {
      let new_g =
        places_we_can_remove_a_box
        |> list.fold(g, fn(p, location) {
          let #(x, y) = location
          p |> utils.grid_set_at(x, y, Empty)
        })
      list.length(places_we_can_remove_a_box)
      + remove_boxes_until_we_cant(new_g)
    }
  }
}
