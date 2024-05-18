import gleam/io

// Uncomment this block to pass the first stage

import gleam/bytes_builder
import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/actor
import glisten

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
pub fn on_new_connection(_conn: glisten.Connection(Nil)) {
  #(Nil, None)
}

/// Socket event loop handler
pub fn socket_event_loop(
  _msg: glisten.Message(nil),
  state: Nil,
  conn: glisten.Connection(Nil),
) {
  let pong_response = bytes_builder.from_string("+PONG\r\n")
  let assert Ok(_) = glisten.send(conn, pong_response)
  actor.continue(state)
}
