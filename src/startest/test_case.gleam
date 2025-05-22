import gleam/dynamic/decode.{type Decoder} as dec
import startest/internal/unsafe
import startest/test_failure.{type TestFailure}

pub type TestBody =
  fn() -> Nil

/// A test case.
pub type Test {
  Test(name: String, body: TestBody, skipped: Bool)
}

/// The outcome of a `Test` that has been run.
pub type TestOutcome {
  Passed
  Failed(TestFailure)
  Skipped
}

/// A `Test` that has been executed and has a `TestOutcome`.
pub type ExecutedTest {
  ExecutedTest(test_case: Test, outcome: TestOutcome)
}

@target(erlang)
pub fn test_decoder() -> Decoder(Test) {
  use name <- dec.then(dec.at([1], dec.string))
  use body <- dec.then(dec.at([2], test_body_decoder()))
  use skipped <- dec.then(dec.at([3], dec.bool))
  dec.success(Test(name, body, skipped))
}

@target(javascript)
pub fn test_decoder() -> Decoder(Test) {
  use name <- dec.field("name", dec.string)
  use body <- dec.field("body", test_body_decoder())
  use skipped <- dec.field("skipped", dec.bool)
  dec.success(Test(name, body, skipped))
}

fn test_body_decoder() -> Decoder(TestBody) {
  use value <- dec.then(dec.dynamic)
  let function: TestBody = unsafe.coerce(value)
  dec.success(function)
}
