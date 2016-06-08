# RiPCord [![Build Status](https://travis-ci.org/klaustopher/ripcord.svg?branch=master)](https://travis-ci.org/klaustopher/ripcord)

This is a [JSON-RPC 2.0](http://www.jsonrpc.org/specification) implementation. It is heavily based on [JSONRPC::Client](https://github.com/fxposter/jsonrpc-client) but has a lot of changes
from the initial implementation that are sort of specific to our use case. But it might work for you as well ;)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ripcord'
```

And then execute:

    $ bundle

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/klaustopher/ripcord.

## Special thanks

- [Pavel Forkert](https://github.com/fxposter/) for the initial implementation of `JSONRPC::Client`
- [Clark Germany](https://www.clark.de) for paying me to work on this ;)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
