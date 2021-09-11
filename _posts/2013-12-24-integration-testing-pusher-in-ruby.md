---
title: "Integration Testing Pusher in Ruby"
category: ruby
description: "Using the pusher-fake library to integration test Pusher in Ruby
without an account or Internet connection."
redirect_from: /2013/12/24/integration-testing-pusher-in-ruby/
---

Real-time websites and notifications have become more and more prominent over
the past few years. And unless you're looking to spend a decent amount of time
supporting different browsers you'll be using a service like [Pusher][1]. It has
been around since 2010 and is used by websites like [Travis CI][2] and
[UserVoice][3].

If you're a Ruby developer you're probably going to have a strong desire to test
Pusher integration. Depending on your usage you might be able to get away with
some [JavaScript][4] and [request][5] stubbing, but it can quickly become a
hassle on larger projects. That's where [pusher-fake][6] comes in, which is
already used to [test production applications][7].

## Getting Started

I've tried to make the fake simple to use while attempting to avoid modifying
your production code as little as possible.

### Dependency

First you'll need to require the dependency in the test environment.

```ruby
group :test do
  gem "pusher-fake"
end
```
{: caption="Adding the library as a test dependency in the Gemfile."}

### JavaScript

Next you'll need to use some custom JavaScript for creating a Pusher instance,
which [sets the appropriate options][8], such as the API key, host, and port.

```erb
<% if defined?(PusherFake) %>
  var instance = <%= PusherFake.javascript %>;
<% else %>
  var instance = new Pusher(...);
<% end %>
```
{: caption="Connecting with library generated JavaScript when testing."}

### Server

And finally if you're using Cucumber you can easily start up the properly
configured servers by including [a helper file][9].

```ruby
require "pusher-fake/support/cucumber"
```
{: caption="Initializing the fake server for Cucumber."}

If you're not using Cucumber, see [the helper file][9] on how to do it manually.

## Usage

Your application should just work as is for testing now, even when offline.
Which includes triggering events from the server, triggering and responding to
webhooks, and triggering and responding to events on the client.

If you want to see and run a very simple test suite using it, check out this
[basic Cucumber example][10]. It uses the [capybara-webkit][11] driver, but it
should work with any driver that supports JavaScript execution.

[1]: https://pusher.com
[2]: https://travis-ci.org
[3]: https://www.uservoice.com
[4]: https://github.com/leggetter/pusher-test-stub
[5]: https://github.com/vcr/vcr
[6]: https://github.com/tristandunn/pusher-fake
[7]: https://semaphoreci.com/blog/2013/06/28/testing-rails-apps-that-use-pusher.html
[8]: https://github.com/tristandunn/pusher-fake/blob/7eab542bb82b08df8348ee675c36048440e8bf2e/lib/pusher-fake.rb#L38-L46
[9]: https://github.com/tristandunn/pusher-fake/blob/main/lib/pusher-fake/support/cucumber.rb
[10]: https://github.com/tristandunn/pusher-fake-example
[11]: https://github.com/thoughtbot/capybara-webkit
