import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor

pub type State {
  State(data: Dict(String, String), self: Option(Subject(Message)))
}

pub type Message {
  Get(key: String, reply_with: Subject(Option(String)))
  Set(key: String, value: String, ttl: Option(Int))
  Clear(key: String)
  SetSelf(subject: Subject(Message))
}

pub type Actor =
  Subject(Message)

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case state.self {
    Some(self) -> {
      case message {
        Get(key, client) -> {
          case dict.get(state.data, key) {
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

        Set(key, value, ttl) -> {
          case ttl {
            Some(ttl_value) -> {
              process.send_after(self, ttl_value, Clear(key))
              Nil
            }
            None -> {
              Nil
            }
          }

          let data =
            state.data
            |> dict.insert(key, value)

          actor.continue(State(data, Some(self)))
        }

        Clear(key) -> {
          let data =
            state.data
            |> dict.delete(key)

          actor.continue(State(data, Some(self)))
        }

        _ -> actor.continue(state)
      }
    }

    _ -> {
      case message {
        SetSelf(self) -> {
          actor.continue(State(state.data, Some(self)))
        }
        _ -> {
          actor.continue(state)
        }
      }
    }
  }
}

pub fn start() -> Actor {
  let assert Ok(subject) = actor.start(State(dict.new(), None), handle_message)
  process.send(subject, SetSelf(subject))

  subject
}
