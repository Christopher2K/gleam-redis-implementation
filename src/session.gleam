import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor

pub type State =
  Dict(String, String)

pub type Message {
  Get(key: String, reply_with: Subject(Option(String)))
  Set(key: String, value: String, ttl: Option(Int))
  Clear(key: String)
}

pub type Actor =
  Subject(Message)

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    Get(key, client) -> {
      case dict.get(state, key) {
        Ok(data) -> {
          process.send(client, option.Some(data))
          actor.continue(state)
        }
        Error(_) -> {
          process.send(client, option.None)
          actor.continue(state)
        }
      }
    }
    _ -> actor.continue(state)
  }
}

pub fn start() -> Actor {
  let assert Ok(subject) = actor.start(dict.new(), handle_message)
  subject
}
