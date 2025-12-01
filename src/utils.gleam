import gleam/regexp
import gleam/result
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
