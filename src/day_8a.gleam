import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import utils

type Vertex =
  #(Int, Int, Int)

type Edge =
  #(Vertex, Vertex)

pub fn main(filename: String, number_of_connections: Int, take_top: Int) -> Int {
  let assert Ok(vertices) = parse(filename)

  let edges = find_all_edges(vertices)

  let edges =
    edges
    |> list.map(fn(edge) {
      let #(a, b) = edge
      #(a, b, distance(a, b))
    })
    |> list.sort(fn(a, b) {
      let #(_, _, a) = a
      let #(_, _, b) = b
      float.compare(a, b)
    })

  let relevant_pairs = list.take(edges, number_of_connections)

  let loops =
    extract_all_loops(
      relevant_pairs
      |> list.map(fn(pair) {
        let #(a, b, _) = pair
        #(a, b)
      })
      |> set.from_list,
    )

  loops
  |> list.map(set.size)
  |> list.sort(fn(a, b) { int.compare(a, b) |> order.negate })
  |> list.take(take_top)
  |> list.fold(1, fn(a, b) { a * b })
}

fn parse(filename: String) -> Result(List(Vertex), String) {
  use lines <- result.try(
    utils.read_lines(filename) |> result.map_error(string.inspect),
  )

  let lines = lines |> list.filter(fn(line) { !string.is_empty(line) })

  use r <- result.try(
    regexp.from_string("^([0-9]+),([0-9]+),([0-9]+)$")
    |> result.map_error(string.inspect),
  )

  lines
  |> utils.match_remaining_lines_regexp(r, fn(m) {
    let regexp.Match(submatches:, ..) = m
    case submatches {
      [option.Some(x), option.Some(y), option.Some(z)] -> {
        use x <- result.try(
          int.parse(x) |> result.map_error(fn(_) { "failed to match x: " <> x }),
        )
        use y <- result.try(
          int.parse(y) |> result.map_error(fn(_) { "failed to match y: " <> y }),
        )
        use z <- result.try(
          int.parse(z) |> result.map_error(fn(_) { "failed to match z: " <> z }),
        )
        Ok(#(x, y, z))
      }
      _ -> Error("failed to parse match: " <> string.inspect(m))
    }
  })
  |> result.map_error(string.inspect)
}

fn find_all_edges(vertices: List(Vertex)) -> List(Edge) {
  case vertices {
    [] -> []
    [_] -> []
    [head, ..tail] ->
      list.append(list.map(tail, fn(v) { #(head, v) }), find_all_edges(tail))
  }
}

fn distance(a: Vertex, b: Vertex) -> Float {
  let #(ax, ay, az) = a
  let #(bx, by, bz) = b
  let xd = int.absolute_value(bx - ax)
  let yd = int.absolute_value(by - ay)
  let zd = int.absolute_value(bz - az)
  case float.square_root({ xd * xd + yd * yd + zd * zd } |> int.to_float) {
    Error(_) -> 0.0
    Ok(result) -> result
  }
}

fn extract_all_loops(remaining_edges: set.Set(Edge)) -> List(set.Set(Vertex)) {
  case extract_loop(remaining_edges) {
    #(option.None, _) -> []
    #(option.Some(loop), remaining_edges) -> [
      loop,
      ..extract_all_loops(remaining_edges)
    ]
  }
}

fn extract_loop(
  remaining_edges: set.Set(Edge),
) -> #(option.Option(set.Set(Vertex)), set.Set(Edge)) {
  case remaining_edges |> set.to_list |> list.first {
    // no edges left
    Error(_) -> #(option.None, remaining_edges)
    Ok(edge) -> {
      let #(a, b) = edge
      let #(loop, remaining_edges) =
        append_to_loop(
          set.new() |> set.insert(a) |> set.insert(b),
          remaining_edges |> set.delete(edge),
        )
      case set.size(loop) {
        0 -> #(option.None, remaining_edges)
        _ -> #(option.Some(loop), remaining_edges)
      }
    }
  }
}

// first result is the updated loop
// second result is the remaining edges, afte removing one if possible
fn append_to_loop(
  loop: set.Set(Vertex),
  remaining_edges: set.Set(Edge),
) -> #(set.Set(Vertex), set.Set(Edge)) {
  case
    remaining_edges
    |> set.filter(fn(edge) {
      let #(a, b) = edge
      set.contains(loop, a) || set.contains(loop, b)
    })
    |> set.to_list
  {
    [] -> #(loop, remaining_edges)
    edges ->
      append_to_loop(
        edges
          |> list.flat_map(fn(edge) {
            let #(a, b) = edge
            [a, b]
          })
          |> list.fold(loop, fn(loop, v) { set.insert(loop, v) }),
        remaining_edges |> set.drop(edges),
      )
  }
}
