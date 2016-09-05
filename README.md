# Tackle

[![Build Status](https://semaphoreci.com/api/v1/renderedtext/tackle/branches/master/badge.svg)](https://semaphoreci.com/renderedtext/tackle)

Tackles the problem of processing asynchronous jobs in reliable manner
by relying on RabbitMQ.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rt-tackle", :require => "tackle"
```

## Usage

### Publishing a message

With tackle, you can publish a message to an AMQP exchange. For example, to
publish `"Hello World!"` do the following:

```ruby
options = {
  :url => "amqp://localhost",
  :exchange => "test-exchange",
  :routing_key => "test-messages",
}

Tackle.publish("Hello World!", options)
```

Optionally, you can pass a dedicated logger to the publish method. This comes
handy if you want to log the status of your publish action to a file.

```ruby
options = {
  :url => "amqp://localhost",
  :exchange => "test-exchange",
  :routing_key => "test-messages",
  :logger => Logger.new("publish.log")
}

Tackle.publish("Hello World!", options)
```

### Consume messages

Tackle enables you to connect to an AMQP exchange and consume messages from it.

```ruby
require "tackle"

options = {
  :url => "amqp://localhost",
  :exchange => "users",
  :routing_key => "signed-up"
  :service => "user-mailer"
}

Tackle.consume(options) do |message|
  puts message
end
```

![Tackle consumer](docs/consumer.png)


### [DEPRECATED] Subscribe to an exchange

**Deprecation notice:** For newer projects please use `Tackle.consume`.

To consume messages from an exchange, do the following:

```ruby
require "tackle"

options = {
  :url => "amqp://localhost",
  :exchange => "test-exchange",
  :routing_key => "test-messages",
  :queue => "test-queue"
}

Tackle.subscribe(options) do |message|
  puts message
end
```

By default, tackle will retry any message that fails to be consumed. To
configure the retry limit and the delay in which the messages will be retried,
do the following:

```ruby
require "tackle"

options = {
  :url => "amqp://localhost",
  :exchange => "test-exchange",
  :routing_key => "test-messages",
  :queue => "test-queue",
  :retry_limit => 8,
  :retry_delay => 30
}

Tackle.subscribe(options) do |message|
  puts message
end
```

Tackle uses the `STDOUT` by default to trace the state of incoming messages. You
can pass a dedicated logger to the `subscribe` method to redirect the output:

```ruby
require "tackle"

options = {
  :url => "amqp://localhost",
  :exchange => "test-exchange",
  :routing_key => "test-messages",
  :queue => "test-queue",
  :retry_limit => 8,
  :retry_delay => 30,
  :logger => Logger.new("subscribe.log")
}

Tackle.subscribe(options) do |message|
  puts message
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake rspec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and
then run `bundle exec rake release`, which will create a git tag for the
version, push git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/renderedtext/tackle.
