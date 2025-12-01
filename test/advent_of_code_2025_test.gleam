import envoy
import gleam/list
import gleam/string
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn is_test_enabled(name: String) -> Bool {
  case envoy.get("TESTS") {
    Error(_) -> True
    Ok(tests) ->
      string.split(tests, on: ",")
      |> list.map(string.trim)
      |> list.contains(name)
  }
}

pub fn run_if_test_is_enabled(name: String, f: fn() -> Nil) {
  case is_test_enabled(name) {
    True -> f()
    False -> Nil
  }
}
