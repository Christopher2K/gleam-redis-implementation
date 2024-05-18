import encoder
import gleeunit/should

pub fn encode_a_simple_string_test() {
  let input = "christopher"

  encoder.encode_string(input)
  |> should.equal(<<"$11\r\nchristopher\r\n":utf8>>)
}
