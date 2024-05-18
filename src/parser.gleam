import gleam/bit_array
import gleam/int
import gleam/list
import gleam/string

const separator = "\r\n"

/// Parse a RESP array
pub fn parse_array(content: BitArray) -> List(String) {
  let assert Ok(content_as_string) = bit_array.to_string(content)
  let assert Ok(#(length, rest)) =
    string.split_once(content_as_string, on: separator)
  let assert Ok(length_as_int) = int.parse(length)

  parse_array_loop([], length_as_int, rest)
}

fn parse_array_loop(
  items: List(String),
  remaining_items: Int,
  content: String,
) -> List(String) {
  case remaining_items {
    0 -> list.reverse(items)
    remaining -> {
      let assert Ok(#(_string_length, rest)) =
        string.split_once(content, on: separator)
      let assert Ok(#(item, rest)) = string.split_once(rest, on: separator)
      parse_array_loop([item, ..items], remaining - 1, rest)
    }
  }
}
