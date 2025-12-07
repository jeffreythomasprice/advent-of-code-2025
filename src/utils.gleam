import gleam/dict
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub type MatchNextLineError {
  MatchNextLineNoLinesRemainingError
  MatchNextLineNextLineDidNotMatchError
  MatchNextLineNextLineProducesMultipleMatchesError
}

pub type MatchLinesUntilError(e) {
  MatchLinesUntilMapperError(e)
  MatchLinesUntilNextLineProducesMultipleMatchesError
  MatchLinesUntilUnmatchedLines
}

pub fn read_lines(
  filename: String,
) -> Result(List(String), simplifile.FileError) {
  use contents <- result.try(simplifile.read(filename))
  Ok(string.split(contents, "\n"))
}

pub fn match_next_line_regexp(
  lines: List(String),
  regexp: regexp.Regexp,
) -> Result(#(regexp.Match, List(String)), MatchNextLineError) {
  case lines {
    [next_line, ..remaining_lines] -> {
      case regexp.scan(regexp, next_line) {
        [result] -> Ok(#(result, remaining_lines))
        [] -> Error(MatchNextLineNextLineDidNotMatchError)
        _ -> Error(MatchNextLineNextLineProducesMultipleMatchesError)
      }
    }
    [] -> Error(MatchNextLineNoLinesRemainingError)
  }
}

pub fn match_lines_regexp_until(
  lines: List(String),
  regexp: regexp.Regexp,
  mapper: fn(regexp.Match) -> Result(t, e),
) -> Result(#(List(t), List(String)), MatchLinesUntilError(e)) {
  case match_next_line_regexp(lines, regexp) {
    Ok(#(match, remainder)) -> {
      case mapper(match) {
        Ok(first_result) -> {
          case match_lines_regexp_until(remainder, regexp, mapper) {
            Ok(#(remaining_results, remaining_lines)) ->
              Ok(#([first_result, ..remaining_results], remaining_lines))
            Error(e) -> Error(e)
          }
        }
        Error(e) -> Error(MatchLinesUntilMapperError(e))
      }
    }
    Error(MatchNextLineNoLinesRemainingError)
    | Error(MatchNextLineNextLineDidNotMatchError) -> Ok(#([], lines))
    Error(MatchNextLineNextLineProducesMultipleMatchesError) ->
      Error(MatchLinesUntilNextLineProducesMultipleMatchesError)
  }
}

pub fn match_remaining_lines_regexp(
  lines: List(String),
  regexp: regexp.Regexp,
  mapper: fn(regexp.Match) -> Result(t, e),
) -> Result(List(t), MatchLinesUntilError(e)) {
  case match_lines_regexp_until(lines, regexp, mapper) {
    Ok(#(results, [])) -> Ok(results)
    Ok(#(_, _)) -> Error(MatchLinesUntilUnmatchedLines)
    Error(e) -> Error(e)
  }
}

pub fn list_of_results_to_result(l: List(Result(t, e))) -> Result(List(t), e) {
  let #(oks, errors) =
    l
    |> list.fold(#([], []), fn(acc, x) {
      let #(oks, errors) = acc
      case x {
        Error(e) -> #(oks, [e, ..errors])
        Ok(t) -> #([t, ..oks], errors)
      }
    })
  let oks = oks |> list.reverse
  let errors = errors |> list.reverse
  case errors {
    [] -> Ok(oks)
    [e, ..] -> Error(e)
  }
}

pub fn iterate_integers(current: Int, step step: Int, end end: Int) -> List(Int) {
  let comparison = case step > 0 {
    True -> fn(a, b) { a <= b }
    False -> fn(a, b) { a >= b }
  }
  case comparison(current, end) {
    True -> [current, ..iterate_integers(current + step, step: step, end: end)]
    False -> []
  }
}

pub type Grid(t) {
  Grid(width: Int, height: Int, data: dict.Dict(#(Int, Int), t))
}

pub fn new_grid(data: List(List(t))) -> Result(Grid(t), String) {
  let height = list.length(data)

  use width <- result.try(
    case data |> list.map(list.length) |> set.from_list |> set.to_list {
      [width] -> Ok(width)
      _ -> Error("no lines or multiple lines of different lengths")
    },
  )

  let data =
    data
    |> list.index_map(fn(row, y) {
      row
      |> list.index_map(fn(value, x) { #(#(x, y), value) })
    })
    |> list.flatten
    |> dict.from_list

  Ok(Grid(width:, height:, data:))
}

pub fn grid_iterate_width(g: Grid(value)) -> List(Int) {
  let Grid(width:, ..) = g
  iterate_integers(0, step: 1, end: width - 1)
}

pub fn grid_iterate_height(g: Grid(value)) -> List(Int) {
  let Grid(height:, ..) = g
  iterate_integers(0, step: 1, end: height - 1)
}

pub fn grid_get_at(g: Grid(value), x: Int, y: Int) -> option.Option(value) {
  let Grid(data:, ..) = g
  case data |> dict.get(#(x, y)) {
    Ok(result) -> option.Some(result)
    Error(_) -> option.None
  }
}

pub fn grid_set_at(g: Grid(value), x: Int, y: Int, value: value) -> Grid(value) {
  let Grid(width:, height:, data:) = g
  let data = data |> dict.insert(#(x, y), value)
  Grid(width:, height:, data:)
}

pub fn grid_to_string(g: Grid(value), to_string: fn(value) -> String) -> String {
  let Grid(width:, height:, ..) = g
  iterate_integers(0, step: 1, end: height - 1)
  |> list.map(fn(y) {
    iterate_integers(0, step: 1, end: width - 1)
    |> list.map(fn(x) {
      let assert option.Some(value) = grid_get_at(g, x, y)
      to_string(value)
    })
    |> string.join("")
  })
  |> string.join("\n")
}
