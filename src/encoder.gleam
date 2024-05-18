import gleam/int
import gleam/string

/// Encode a string value
pub fn encode_string(value: String) -> BitArray {
  let value_length = string.length(value)
  let encoded_value =
    "$" <> int.to_string(value_length) <> "\r\n" <> value <> "\r\n"
  <<encoded_value:utf8>>
}
