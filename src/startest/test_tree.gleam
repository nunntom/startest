import gleam/dynamic/decode.{type Decoder} as dec
import gleam/list
import gleam/string
import startest/test_case.{type Test, test_decoder}

pub type TestTree {
  Suite(name: String, suite: List(TestTree))
  Test(Test)
}

pub fn all_tests(tree: TestTree) -> List(#(String, Test)) {
  collect_all_tests(tree, [], [])
}

fn collect_all_tests(
  tree: TestTree,
  path: List(String),
  acc: List(#(String, Test)),
) -> List(#(String, Test)) {
  case tree {
    Suite(name, suite) ->
      suite
      |> list.flat_map(collect_all_tests(_, [name, ..path], acc))
    Test(test_case) -> {
      let test_path =
        [test_case.name, ..path]
        |> list.reverse
        |> string.join(" ❯ ")

      [#(test_path, test_case), ..acc]
    }
  }
}

@target(erlang)
pub fn test_tree_decoder() -> Decoder(TestTree) {
  dec.one_of(
    {
      use name <- dec.then(dec.at([1], dec.string))
      use suite <- dec.then(dec.at([2], dec.list(test_tree_decoder())))
      dec.success(Suite(name, suite))
    },
    [
      dec.at([1], test_decoder())
      |> dec.map(Test),
    ],
  )
}

@target(javascript)
pub fn test_tree_decoder() -> Decoder(TestTree) {
  dec.one_of(
    {
      use name <- dec.field("name", dec.string)
      use suite <- dec.field("suite", dec.list(test_tree_decoder()))
      dec.success(Suite(name, suite))
    },
    [
      {
        use test_ <- dec.field("0", test_decoder())
        dec.success(Test(test_))
      },
    ],
  )
}
