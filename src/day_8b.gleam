import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import utils

type Vertex =
  #(Int, Int, Int)

type Edge =
  #(Vertex, Vertex)

pub fn main(filename: String) -> Int {
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

  let assert option.Some(winning_edge) =
    append_until_one_loop(
      [],
      edges
        |> list.map(fn(edge) {
          let #(a, b, _) = edge
          #(a, b)
        }),
      list.length(vertices),
    )

  let #(#(ax, _, _), #(bx, _, _)) = winning_edge
  ax * bx
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

fn append_until_one_loop(
  loops: List(set.Set(Vertex)),
  edges: List(Edge),
  expected_vertex_count: Int,
) -> option.Option(Edge) {
  case edges {
    [] -> option.None
    [head, ..tail] -> {
      let loops = append_to_loops(loops, head)
      case loops {
        [single_loop] -> {
          case set.size(single_loop) == expected_vertex_count {
            True -> option.Some(head)
            False -> append_until_one_loop(loops, tail, expected_vertex_count)
          }
        }
        _ -> append_until_one_loop(loops, tail, expected_vertex_count)
      }
    }
  }
}

fn append_to_loops(
  loops: List(set.Set(Vertex)),
  edge: Edge,
) -> List(set.Set(Vertex)) {
  let #(a, b) = edge
  let loop_a = loops |> list.find(fn(loop) { set.contains(loop, a) })
  let loop_b = loops |> list.find(fn(loop) { set.contains(loop, b) })
  case loop_a, loop_b {
    // both points already exist in the same loop
    Ok(loop_a), Ok(loop_b) if loop_a == loop_b -> loops
    // both points exist, but in different loops
    Ok(loop_a), Ok(loop_b) -> [
      set.union(loop_a, loop_b),
      ..{
        loops
        |> list.filter(fn(existing) { existing != loop_a && existing != loop_b })
      }
    ]
    // one point is new, the other is in an existing loop, append to that loop
    Ok(loop), Error(_) | Error(_), Ok(loop) -> [
      loop |> set.insert(a) |> set.insert(b),
      // don't include the existing version of the loop as well
      ..{ loops |> list.filter(fn(existing) { existing != loop }) }
    ]
    // no existing loop contains either point, start a new one
    Error(_), Error(_) -> [set.new() |> set.insert(a) |> set.insert(b), ..loops]
  }
}
