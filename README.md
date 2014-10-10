# Testrail::Rspec

This gem provides custom RSpec formatter allowing to export test results directly to [TestRail][1] instance via their [API][2].

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'testrail-rspec'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install testrail-rspec

## Usage

### Configuration

via RSpec.configure in spec_helper.rb - describe it in more details when decided how it is done

add to .rspec file this way:

    $ --format TestLink::Exporter

or use it from commandline this way:

    $ rspec spec --format TestLink::Exporter

## Contributing

1. Fork it ( https://github.com/[my-github-username]/testrail-rspec/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[1]: http://www.gurock.com/testrail/            "TestRail"
[2]: http://docs.gurock.com/testrail-api2/start "TestRail API"