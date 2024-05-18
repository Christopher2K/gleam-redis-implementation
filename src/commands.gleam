import gleam/bytes_builder
import gleam/dict.{type Dict}
import gleam/io
import gleam/list

import encoder

pub type State =
  Dict(String, String)

pub fn handle_unknown_command(command: String, state: State) {
  io.debug("Unsupported command: " <> command)
  #(bytes_builder.from_string(""), state)
}

pub fn handle_ping(state: State) {
  #(bytes_builder.from_string("+PONG\r\n"), state)
}

pub fn handle_echo_command(args: List(String), state: State) {
  let assert Ok(arg) = list.at(args, 0)

  #(
    arg
      |> encoder.encode_string()
      |> bytes_builder.from_bit_array(),
    state,
  )
}

pub fn handle_get_command(args: List(String), state: Dict(String, String)) {
  let assert Ok(arg) = list.at(args, 0)
  #(
    case dict.get(state, arg) {
      Ok(data) ->
        data
        |> encoder.encode_string()
        |> bytes_builder.from_bit_array()

      Error(_) -> bytes_builder.from_string("$-1\r\n")
    },
    state,
  )
}

pub fn handle_set_command(args: List(String), state: Dict(String, String)) {
  let assert [key, value] = args
  let new_state = dict.insert(state, key, value)
  #(bytes_builder.from_string("+OK\r\n"), new_state)
}
