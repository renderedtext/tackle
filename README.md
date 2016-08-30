# Tackle

[![Build Status](https://semaphoreci.com/api/v1/projects/b39e2ae2-2516-4fd7-9e2c-f5be1a043ff5/732979/badge.svg)](https://semaphoreci.com/renderedtext/tackle)

Tackles the problem of processing asynchronous jobs in reliable manner by relying on RabbitMQ.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "tackle", :git => "https://github.com/renderedtext/tackle"
```

## Usage

### Subscribe consumer:

```ruby
require "tackle"

options = {
  :url         => "amqp://localhost", # optional
  :exchange    => "test-exchange",    # required
  :routing_key => "test-messages",    # required
  :queue       => "test-queue",       # required
  :retry_limit => 8,                  # optional
  :retry_delay => 30,                 # optional
  :logger      => Logger.new(STDOUT)  # optional
}

Tackle.subscribe(options) do |message|
  # Do something with message
end
```

### Publish message:

```ruby

options = {
  :url         => "amqp://localhost", # optional
  :exchange    => "test-exchange",    # required
  :routing_key => "test-messages",    # required
  :logger      => Logger.new(STDOUT)  # optional
}

Tackle.publish("Hello, world!", options)
```

## Development


After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/renderedtext/tackle
