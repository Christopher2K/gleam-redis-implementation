import gleam/io

// Uncomment this block to pass the first stage
import gleam/bytes_builder
import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import gleam/string
import glisten

import commands
import parser
import session.{type Actor}

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
  let actor = session.start()
  #(actor, None)
}

/// Socket event loop handler
pub fn socket_event_loop(
  msg: glisten.Message(_),
  state: Actor,
  conn: glisten.Connection(_),
) {
  let assert glisten.Packet(data) = msg

  let response = case data {
    <<"*":utf8, content:bytes>> -> {
      let assert [command, ..args] = parser.parse_array(content)
      let command = string.lowercase(command)

      case command {
        "echo" -> commands.handle_echo_command(args)
        "ping" -> commands.handle_ping()
        "get" -> commands.handle_get_command(args, state)
        "set" -> commands.handle_set_command(args, state)
        _ -> commands.handle_unknown_command(command)
      }
    }
    _ -> {
      io.println("Unsupported datatype")
      bytes_builder.from_string("")
    }
  }

  let assert Ok(_) = glisten.send(conn, response)
  actor.continue(state)
}
