import gleam/io

// Uncomment this block to pass the first stage
import gleam/bytes_builder
import gleam/erlang/process
import gleam/list
import gleam/option.{None}
import gleam/otp/actor
import gleam/string
import glisten

import encoder
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
  #(Nil, None)
}

/// Socket event loop handler
pub fn socket_event_loop(
  msg: glisten.Message(_),
  state: Nil,
  conn: glisten.Connection(_),
) {
  let assert glisten.Packet(data) = msg

  let response = case data {
    <<"*":utf8, content:bytes>> -> {
      let result = parser.parse_array(content)
      let assert Ok(command) = list.at(result, 0)
      let command = string.lowercase(command)

      case command {
        "echo" -> {
          let assert Ok(argument) =
            result
            |> list.at(1)

          argument
          |> encoder.encode_string()
          |> bytes_builder.from_bit_array()
        }

        "ping" -> bytes_builder.from_string("+PONG\r\n")

        _ -> {
          io.println("Unsupported command")
          bytes_builder.from_string("")
        }
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
