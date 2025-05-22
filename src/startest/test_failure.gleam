import exception.{type Exception}
import gleam/dynamic/decode
import gleam/result
import gleam/string
import startest/assertion_error.{
  type RescuedAssertionError, RescuedAssertionError,
}

pub type TestFailure {
  AssertionError(RescuedAssertionError)
  GenericError(Exception)
}

pub fn rescue(f: fn() -> Nil) -> Result(Nil, TestFailure) {
  case exception.rescue(f) {
    Ok(Nil) -> Ok(Nil)
    Error(exception) -> {
      let panic_info =
        exception
        |> try_decode_panic_info
      case panic_info {
        Ok(panic_info) ->
          Error(AssertionError(RescuedAssertionError(panic_info.message)))
        Error(Nil) -> Error(GenericError(exception))
      }
    }
  }
}

pub fn to_string(failure: TestFailure) -> String {
  case failure {
    AssertionError(assertion_error) -> assertion_error.message
    GenericError(exception) -> string.inspect(exception)
  }
}

type PanicInfo {
  PanicInfo(module: String, function: String, line: Int, message: String)
}

type PanicKey {
  Module
  Function
  Message
  Line
}

fn try_decode_panic_info(exception: Exception) -> Result(PanicInfo, Nil) {
  let err = case exception {
    exception.Errored(err) | exception.Thrown(err) | exception.Exited(err) ->
      err
  }

  let decoder =
    decode.one_of(
      {
        use module <- decode.then(decode.at([Module], decode.string))
        use function <- decode.then(decode.at([Function], decode.string))
        use line <- decode.then(decode.at([Line], decode.int))
        use message <- decode.then(decode.at([Message], decode.string))
        decode.success(PanicInfo(module, function, line, message))
      },
      [
        {
          use module <- decode.field("module", decode.string)
          use function <- decode.field("function", decode.string)
          use line <- decode.field("line", decode.int)
          use message <- decode.field("message", decode.string)
          decode.success(PanicInfo(module, function, line, message))
        },
      ],
    )

  decode.run(err, decoder)
  |> result.replace_error(Nil)
}
