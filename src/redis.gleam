import gleam/io

// Uncomment this block to pass the first stage
import gleam/bytes_builder
import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import gleam/string
import glisten

import commands
import parser

pub fn main() {
  // You can use print statements as follows for debugging, they'll be visible when running tests.
  io.println("Logs from your program will appear here!")
  // Uncomment this block to pass the first stage

  let assert Ok(_) =
    glisten.handler(on_new_connection, socket_event_loop)
    |> glisten.serve(6379)

  process.sleep_forever()
}

/// On new socket connection
pub fn on_new_connection(_conn: glisten.Connection(_)) {
  #(dict.new(), None)
}

/// Socket event loop handler
pub fn socket_event_loop(
  msg: glisten.Message(_),
  state: Dict(String, String),
  conn: glisten.Connection(_),
) {
  let assert glisten.Packet(data) = msg

  let #(response, new_state) = case data {
    <<"*":utf8, content:bytes>> -> {
      let assert [command, ..args] = parser.parse_array(content)
      let command = string.lowercase(command)

      case command {
        "echo" -> commands.handle_echo_command(args, state)
        "ping" -> commands.handle_ping(state)
        "get" -> commands.handle_get_command(args, state)
        "set" -> commands.handle_set_command(args, state)
        _ -> commands.handle_unknown_command(command, state)
      }
    }
    _ -> {
      io.println("Unsupported datatype")
      #(bytes_builder.from_string(""), state)
    }
  }

  let assert Ok(_) = glisten.send(conn, response)
  actor.continue(new_state)
}
