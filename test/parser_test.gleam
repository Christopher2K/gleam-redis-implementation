import gleeunit/should
import parser

pub fn parse_simple_array_test() {
  let input = <<"2\r\n$5\r\nhello\r\n$5\r\nworld\r\n":utf8>>

  parser.parse_array(input)
  |> should.equal(["hello", "world"])
}
