# MQRouter

This gem is for use in our ruby apps for communicating with other microservices
over a rabbitmq server.

## Usage

### Required ENV Vars

```
RABBIT_URL # example "amqps://username:password@rabbit.com/something"
```

### Message Handlers

Message Handlers will define a queue they want to watch on a given exchange and
for a rails app should be placed in

	app/queue/

An example handler would look like this:

```ruby
class ExampleQueue < MQRouter::MessageHandler
  # watch takes the exchange, routing key, and an optional queue name 
  watch 'activity', 'codex.translate'

  # Each handler needs a receive method that will be called when new data is available
  def receive(packet)
    begin
      some_payload = Danger.do_some_risky_thing msg
      respond_with result(some_payload, 202) // The second parameter is an optional status code
    rescue Exception => ex
      respond_with error(ex)
    end
  end
end
```

### Methods

`respond_with(packet, opts={})` takes a packet, automatically sets the
`correlation_id` and `routing_key` if available, then ships it out to the queue.
`opts` can be used to send your own options to the the underlying bunny library
and override defaults.

`result(data, status_code=200)` returns a packet that can be handed to
`respond_with`. It takes an object of what you want to be the body of your packet
and an optional status_code.

`error(data, status_code=500)` returns a packet that can be handed to
`respond_with`. It takes an object of what you want to be the body of your packet
and an optional `status_code`. It also automatically sends the error packet over
the _error_ exchange to the corresponding queue.

Responding to an RPC call is automatically handled by MQRouter. You don't need
to worry about managing responses. You simply call respond_with a result or an
error. The first parameter is the data that will be shipped back in the body:
field of the response. The second parameter is an optional status_code. The
default for result is 200 and the default for error is 500. To override these
just provide a second parameter.

The error method will automatically handle wrapping the error and reporting it
back to the calling application if it's waiting for a response, and piping it
out to the error queue.
