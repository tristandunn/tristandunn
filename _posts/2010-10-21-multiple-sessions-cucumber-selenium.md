---
title: "Multiple Sessions in Cucumber"
category: ruby
description: "Capybara additions for session manipulation to allow for testing interaction between multiple sessions in Cucumber."
archived: true
---

<p class="outdated">This is now included in the <a href="https://github.com/jnicklas/capybara">Capybara</a> library.</p>

Multiple sessions are not often needed when writing Cucumber scenarios.
Normally to validate that a user can or can not see what another user created
you would simply sign in as another user. However, this is not the case when you
use WebSockets to deliver information in real-time. If you were to sign in as
another user there would be no record of the previous events.

## The Solution

While searching for a solution I found "Cucumber Testing for Multiple Users"
by [Bernard Potocki][1]. He shows how to achieve multiple sessions with Cucumber and
Selenium, but I wanted to make it easier.

Drop the following into `cucumber/support/sessions.rb`.

<figure>
{% highlight ruby %}
module Capybara
  module Driver
    module Sessions
      def set_session(id)
        Capybara.instance_variable_set("@session_pool", {
          "#{Capybara.current_driver}#{Capybara.app.object_id}" => $sessions[id]
        })
      end

      def in_session(id, &block)
        $sessions ||= {}
        $sessions[:default] ||= Capybara.current_session
        $sessions[id]       ||= Capybara::Session.new(Capybara.current_driver, Capybara.app)

        set_session(id)

        yield

        set_session(:default)
      end
    end
  end
end

World(Capybara::Driver::Sessions)
{% endhighlight %}
  <figcaption>Adding methods for manipulating the Capybara session.</figcaption>
</figure>

Now you can write step definitions such as:

<figure>
{% highlight ruby %}
Given /^a user named "([^"]*)" is online$/ do |name|
  in_session(name) do
    Given %{I am on the homepage}
    When  %{I fill in "Name" with "#{name}"}
    And   %{I submit the new user form}
  end
end
{% endhighlight %}
  <figcaption>Using the new method for switching sessions temporarily.</figcaption>
</figure>

Which allows for scenarios to deal with multiple sessions.

<figure>
{% highlight cucumber %}
@javascript
Scenario: Visitor creates a user successfully with another user is online
  Given a user named "Sue" is online             # Create a new session and user.
  And I go to the homepage                       # Back in the original session.
  When I fill in "Name" with "Bob"
  And I submit the new user form
  Then I should be on the users page
  And Sue should see "Bob has entered the room." # Switches to the "Sue" session.
{% endhighlight %}
  <figcaption>Writing a feature with two users interacting.</figcaption>
</figure>

## Conclusion &#38; Example

It's very comforting knowing that I can test interactions between two users
now. And while I have not tried it yet, you can potentially test interactions
between a group of users.

I have created a basic example, [cucumber-websocket-example][2], which
demonstrates the above code.

[1]: https://twitter.com/_imanel
[2]: https://github.com/tristandunn/cucumber-websocket-example/
