# Tackle

[![Build Status](https://semaphoreci.com/api/v1/projects/b39e2ae2-2516-4fd7-9e2c-f5be1a043ff5/732979/badge.svg)](https://semaphoreci.com/renderedtext/tackle)

Tackles the problem of processing asynchronous jobs in reliable manner by relying on RabbitMQ.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "tackle"
```

## Usage

```ruby
require "tackle/worker"

class ReliableWorker

  def initialize
    @worker = Tackle::Worker.new("test-exchange",
                                 "test-queue", :url => "amqp://localhost:5672"
                                               :retry_limit => 2,
                                               :retry_delay => 15,
                                               :logger => logger)
  end

  def run
    @worker.subscribe { |message| perform(message) }
  end

  def perform(message)
    # do something fun
  end

end
```

### How to run Tackle workers

Subscribe call will block and wait for messages so you have to run each worker in it's own process.

```ruby
namespace :app do
  desc "Processes messages realiably"
  task :start_worker => :environment do
    ReliableWorker.new.run
  end
end
```

Run your task with:

```bash
bundle exec rake app:start_worker
```

## Development


After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/tackle.


