import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/set.{type Set}

const timeout: Int = 5000

pub type Message {
  AddItem(item: String)
  TakeItem(reply_with: Subject(Result(String, Nil)), item: String)
  Shutdown
}

fn handle_message(
  pantry: Set(String),
  message: Message,
) -> actor.Next(Set(String), Message) {
  case message {
    Shutdown -> actor.stop()
    AddItem(item) -> actor.continue(set.insert(pantry, item))
    TakeItem(client, item) -> {
      case set.contains(pantry, item) {
        False -> {
          process.send(client, Error(Nil))
          actor.continue(pantry)
        }
        True -> {
          process.send(client, Ok(item))
          actor.continue(set.delete(pantry, item))
        }
      }
    }
  }
}

pub fn new() -> Subject(Message) {
  let assert Ok(actor) =
    actor.new(set.new()) |> actor.on_message(handle_message) |> actor.start
  actor.data
}

pub fn add_item(pantry: Subject(Message), item: String) -> Nil {
  // process.send(pantry, AddItem(item))
  actor.send(pantry, AddItem(item))
}

pub fn take_item(pantry: Subject(Message), item: String) -> Result(String, Nil) {
  // process.call(pantry, timeout, TakeItem(_, item))
  actor.call(pantry, timeout, TakeItem(_, item))
}

pub fn close(pantry: Subject(Message)) -> Nil {
  actor.send(pantry, Shutdown)
}
