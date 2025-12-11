import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import utils

type Point =
  #(Int, Int)

type Edge {
  Horizontal(y: Int, x1: Int, x2: Int)
  Vertical(x: Int, y1: Int, y2: Int)
}

type Rectangle {
  Rectangle(min: Point, max: Point)
}

pub fn main(filename: String) -> Int {
  let assert Ok(vertices) = parse(filename)
  // echo vertices as "TODO vertices"

  let assert Ok(edges) = find_edges(vertices)
  echo edges as "TODO edges"

  let unique_x =
    edges
    |> list.map(fn(e) {
      case e {
        Horizontal(y:, x1:, x2:) -> [x1, x2]
        Vertical(x:, y1:, y2:) -> [x]
      }
    })
    |> list.flatten
    |> list.unique
    |> list.sort(int.compare)
  echo unique_x as "TODO unique_x"

  let edges = split_edges(edges, unique_x)
  echo edges as "TODO edges, after splitting"

  let rectangles_in_shape =
    unique_x
    |> pairs
    |> list.map(fn(x) {
      let #(ex1, ex2) = x
      edges
      |> list.filter_map(fn(e) {
        case e {
          Horizontal(y:, x1:, x2:) ->
            case x1 == ex1 && x2 == ex2 {
              True -> Ok(#(y, x1, x2))
              False -> Error(Nil)
            }
          Vertical(..) -> Error(Nil)
        }
      })
    })
    |> list.map(fn(group) {
      group
      |> list.sort(fn(a, b) {
        let #(ay, _, _) = a
        let #(by, _, _) = b
        int.compare(ay, by)
      })
      |> pairs
      |> list.map(fn(pair) {
        let #(#(y1, x1, _), #(y2, _, x2)) = pair
        new_rectangle(#(x1, y1), #(x2, y2))
      })
    })
    |> list.flatten
  echo rectangles_in_shape as "TODO rectangles_in_shape"

  // print_rectangles("TODO shape: ", rectangles_in_shape, 13, 13)

  // let r = new_rectangle(#(3, 2), #(4, 3))
  // echo r as "TODO r"
  // print_rectangles("TODO r:     ", [r], 13, 13)

  // let subtraction =
  //   echo subtract_all_rectangles(r, rectangles_in_shape) as "TODO subtraction"
  // print_rectangles("TODO sub:   ", subtraction, 13, 13)

  // echo is_rectangle_entirely_covered(r, rectangles_in_shape)
  //   as "TODO is_rectangle_entirely_covered"

  // todo
  find_largest_rectangle(vertices, rectangles_in_shape)
}

fn parse(filename: String) -> Result(List(Point), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )

  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  use r <- result.try(
    regexp.from_string("^([0-9]+),([0-9]+)$")
    |> result.map_error(string.inspect),
  )

  lines
  |> utils.match_remaining_lines_regexp(r, fn(m) {
    let regexp.Match(submatches:, ..) = m
    case submatches {
      [option.Some(x), option.Some(y)] -> {
        use x <- result.try(
          int.parse(x) |> result.map_error(fn(_) { "failed to match x: " <> x }),
        )
        use y <- result.try(
          int.parse(y) |> result.map_error(fn(_) { "failed to match y: " <> y }),
        )
        Ok(#(x, y))
      }
      _ -> Error("failed to parse match: " <> string.inspect(m))
    }
  })
  |> result.map_error(string.inspect)
}

fn find_edges(vertices: List(Point)) -> Result(List(Edge), String) {
  case list.last(vertices) {
    Error(_) -> []
    Ok(last) -> [last, ..vertices] |> pairs
  }
  |> list.map(fn(e) {
    let #(#(x1, y1), #(x2, y2)) = e
    let xd = int.absolute_value(x2 - x1)
    let yd = int.absolute_value(y2 - y1)
    case xd, yd {
      0, _ -> Ok(Vertical(x1, int.min(y1, y2), int.max(y1, y2)))
      _, 0 -> Ok(Horizontal(y1, int.min(x1, x2), int.max(x1, x2)))
      // puzzle says this should never happen
      _, _ -> Error("bad edge: " <> string.inspect(e))
    }
  })
  |> utils.list_of_results_to_result
}

fn pairs(l: List(t)) -> List(#(t, t)) {
  case l {
    [] | [_] -> []
    [a, b, ..tail] -> [#(a, b), ..pairs([b, ..tail])]
  }
}

fn split_edges(edges: List(Edge), unique_x: List(Int)) -> List(Edge) {
  edges
  |> list.map(fn(e) {
    case e {
      Horizontal(y:, x1:, x2:) -> {
        let new_x = unique_x |> list.filter(fn(x) { x > x1 && x < x2 })
        let new_x = [x1, ..new_x] |> list.append([x2])
        pairs(new_x)
        |> list.map(fn(x) {
          let #(x1, x2) = x
          Horizontal(y:, x1:, x2:)
        })
      }
      Vertical(..) -> [e]
    }
  })
  |> list.flatten
}

fn find_largest_rectangle(
  vertices: List(Point),
  other_rectangles: List(Rectangle),
) -> Int {
  case vertices {
    [] | [_] -> 0
    [head, ..tail] ->
      int.max(
        case
          tail
          |> list.map(fn(b) {
            let r = new_rectangle(head, b)
            #(r, area(r))
          })
          |> list.sort(fn(a, b) {
            let #(_, area_a) = a
            let #(_, area_b) = b
            int.compare(area_b, area_a)
          })
          |> list.find_map(fn(r) {
            echo r as "TODO testing rectangle"
            let #(r, area) = r
            case is_rectangle_entirely_covered(r, other_rectangles) {
              True -> Ok(area)
              False -> Error(Nil)
            }
          })
        {
          Ok(area) -> area
          Error(_) -> 0
        },
        find_largest_rectangle(tail, other_rectangles),
      )
  }
}

fn area(r: Rectangle) -> Int {
  let Rectangle(min: #(x1, y1), max: #(x2, y2)) = r
  let xd = int.absolute_value(x2 - x1) + 1
  let yd = int.absolute_value(y2 - y1) + 1
  xd * yd
}

fn is_rectangle_entirely_covered(
  r: Rectangle,
  other_rectangles: List(Rectangle),
) -> Bool {
  case subtract_all_rectangles(r, other_rectangles) {
    [] -> True
    _ -> False
  }
}

fn subtract_all_rectangles(
  r: Rectangle,
  other_rectangles: List(Rectangle),
) -> List(Rectangle) {
  case other_rectangles {
    [] -> [r]
    [r2, ..tail] ->
      subtract_rectangles(r, r2)
      |> list.flat_map(fn(r) { subtract_all_rectangles(r, tail) })
  }
}

fn subtract_rectangles(r1: Rectangle, r2: Rectangle) -> List(Rectangle) {
  let Rectangle(min: #(r2x1, r2y1), max: #(r2x2, r2y2)) = r2

  let results = []

  let #(inside, outside) = rectangle_split_inside_is_positive_x(r1, r2x1)
  let results = case outside {
    option.None -> results
    option.Some(x) -> [x, ..results]
  }

  let #(inside, results) = case
    inside
    |> option.map(fn(remainder) {
      let #(inside, outside) =
        rectangle_split_inside_is_positive_y(remainder, r2y1)
      let results = case outside {
        option.None -> results
        option.Some(x) -> [x, ..results]
      }
      #(inside, results)
    })
  {
    option.None -> #(option.None, results)
    option.Some(x) -> x
  }

  let #(inside, results) = case
    inside
    |> option.map(fn(remainder) {
      let #(inside, outside) =
        rectangle_split_inside_is_negative_x(remainder, r2x2)
      let results = case outside {
        option.None -> results
        option.Some(x) -> [x, ..results]
      }
      #(inside, results)
    })
  {
    option.None -> #(option.None, results)
    option.Some(x) -> x
  }

  let #(_, results) = case
    inside
    |> option.map(fn(remainder) {
      let #(inside, outside) =
        rectangle_split_inside_is_negative_y(remainder, r2y2)
      let results = case outside {
        option.None -> results
        option.Some(x) -> [x, ..results]
      }
      #(inside, results)
    })
  {
    option.None -> #(option.None, results)
    option.Some(x) -> x
  }

  results
}

// #(inside, outside)
// portion of rectangle that includes vertical line through x is considered inside, x + 1 is outside
fn rectangle_split_inside_is_negative_x(
  r: Rectangle,
  x: Int,
) -> #(option.Option(Rectangle), option.Option(Rectangle)) {
  let Rectangle(min: #(rx1, ry1), max: #(rx2, ry2)) = r
  case rx2 <= x, rx1 > x {
    // all inside
    True, _ -> #(option.Some(r), option.None)
    // all outside
    _, True -> #(option.None, option.Some(r))
    // split
    _, _ -> #(
      option.Some(new_rectangle(#(rx1, ry1), #(x, ry2))),
      option.Some(new_rectangle(#(x + 1, ry1), #(rx2, ry2))),
    )
  }
}

// #(inside, outside)
// portion of rectangle that includes vertical line through x is considered inside, x - 1 is outside
fn rectangle_split_inside_is_positive_x(
  r: Rectangle,
  x: Int,
) -> #(option.Option(Rectangle), option.Option(Rectangle)) {
  let Rectangle(min: #(rx1, ry1), max: #(rx2, ry2)) = r
  case rx1 >= x, rx2 < x {
    // all inside
    True, _ -> #(option.Some(r), option.None)
    // all outside
    _, True -> #(option.None, option.Some(r))
    // split
    _, _ -> #(
      option.Some(new_rectangle(#(x, ry1), #(rx2, ry2))),
      option.Some(new_rectangle(#(x - 1, ry1), #(rx1, ry2))),
    )
  }
}

// #(inside, outside)
// portion of rectangle that includes horizontal line through y is considered inside, y + 1 is outside
fn rectangle_split_inside_is_negative_y(
  r: Rectangle,
  y: Int,
) -> #(option.Option(Rectangle), option.Option(Rectangle)) {
  let Rectangle(min: #(rx1, ry1), max: #(rx2, ry2)) = r
  case ry2 <= y, ry1 > y {
    // all inside
    True, _ -> #(option.Some(r), option.None)
    // all outside
    _, True -> #(option.None, option.Some(r))
    // split
    _, _ -> #(
      option.Some(new_rectangle(#(rx1, ry1), #(rx2, y))),
      option.Some(new_rectangle(#(rx1, y + 1), #(rx2, ry2))),
    )
  }
}

// #(inside, outside)
// portion of rectangle that includes horizontal line through y is considered inside, y - 1 is outside
fn rectangle_split_inside_is_positive_y(
  r: Rectangle,
  y: Int,
) -> #(option.Option(Rectangle), option.Option(Rectangle)) {
  let Rectangle(min: #(rx1, ry1), max: #(rx2, ry2)) = r
  case ry1 >= y, ry2 < y {
    // all inside
    True, _ -> #(option.Some(r), option.None)
    // all outside
    _, True -> #(option.None, option.Some(r))
    // split
    _, _ -> #(
      option.Some(new_rectangle(#(rx1, y), #(rx2, ry2))),
      option.Some(new_rectangle(#(rx1, y - 1), #(rx2, ry1))),
    )
  }
}

fn new_rectangle(p1: Point, p2: Point) -> Rectangle {
  let #(p1x, p1y) = p1
  let #(p2x, p2y) = p2
  Rectangle(min: #(int.min(p1x, p2x), int.min(p1y, p2y)), max: #(
    int.max(p1x, p2x),
    int.max(p1y, p2y),
  ))
}

fn print_rectangles(prefix: String, r: List(Rectangle), width: Int, height: Int) {
  utils.iterate_integers(0, step: 1, end: height)
  |> list.map(fn(y) {
    let line =
      utils.iterate_integers(0, step: 1, end: width)
      |> list.map(fn(x) {
        case point_in_any_rectangle(r, #(x, y)) {
          False -> "."
          True -> "X"
        }
      })
      |> string.join("")
    io.println(prefix <> line)
  })
}

fn point_in_any_rectangle(r: List(Rectangle), p: Point) -> Bool {
  list.any(r, fn(r) { point_in_rectangle(r, p) })
}

fn point_in_rectangle(r: Rectangle, p: Point) -> Bool {
  let Rectangle(min: #(rx1, ry1), max: #(rx2, ry2)) = r
  let #(px, py) = p
  px >= rx1 && px <= rx2 && py >= ry1 && py <= ry2
}
