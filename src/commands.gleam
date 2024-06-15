import gleam/bytes_builder
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}

import encoder
import session.{type Actor}

pub fn handle_unknown_command(command: String) {
  io.debug("Unsupported command: " <> command)
  bytes_builder.from_string("")
}

pub fn handle_ping() {
  bytes_builder.from_string("+PONG\r\n")
}

pub fn handle_echo_command(args: List(String)) {
  let assert Ok(arg) = list.at(args, 0)

  arg
  |> encoder.encode_string()
  |> bytes_builder.from_bit_array()
}

pub fn handle_get_command(args: List(String), actor: Actor) {
  let assert Ok(key) = list.at(args, 0)

  let response =
    process.call(actor, fn(subject) { session.Get(key, subject) }, 1000)

  case response {
    Some(data) ->
      data
      |> encoder.encode_string()
      |> bytes_builder.from_bit_array()
    None -> bytes_builder.from_string("$-1\r\n")
  }
}

pub fn handle_set_command(args: List(String), actor: Actor) {
  let assert [key, value, ..rest] = args

  let ttl = case rest {
    ["px", value] -> {
      let assert Ok(parsed_value) = int.parse(value)
      Some(parsed_value)
    }
    _ -> {
      None
    }
  }

  // TODO: Maybe this should return something like a Result
  process.send(actor, session.Set(key, value, ttl))
  bytes_builder.from_string("+OK\r\n")
}
