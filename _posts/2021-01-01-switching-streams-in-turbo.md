---
title: "Switching Streams in Turbo Rails"
image: "posts/2021-01-01/image@2x.png"
category: rails
description: "How to easily switch a user between Turbo streams without writing JavaScript."
permalink: /journal/switching-streams-turbo-rails/
---

Basecamp recently announced [Hotwire][] and it seemed like a perfect replacement
to complicated React code I was using to build a browser-based, role-playing
game. While still a little rough around the edges, it's impressive how a
few HTML elements can change how interactive a website is.

> Hotwire is an alternative approach to building modern web applications without
> using much JavaScript by sending HTML instead of JSON over the wire.

## Subscribing to Streams

The game is based around the concept of individual rooms which isolate
communication, items, enemies, etc. Characters stream from the room they're in
to receive messages.

```erb
<div id="streams">
  <%= turbo_stream_from current_character.room %>
</div>
```
{: caption="Example of creating a stream subscription."}

Behind the seasons it creates a custom `<turbo-cable-stream-source>` element,
which triggers a channel subscription via [Action Cable][]. Now we can trigger
the standard [stream events][] to append, prepend, replace, and remove elements
from the target.

## Unsubscribing from Streams

When a character in the game leaves a room, they need to unsubscribe from the
room their leaving and subscribe to the room their joining. The new subscription
is done the same as before, but unsubscribing from a stream wasn't clear to me
from the documentation.

After digging into the `turbo-rails` code, I noticed that when a stream element
is disconnected it'll automatically unsubscribe.

```js
class TurboCableStreamSourceElement extends HTMLElement {
  // ...

  disconnectedCallback() {
    disconnectStreamSource(this)
    if (this.subscription) this.subscription.unsubscribe()
  }

  // ...
}
```
{: caption="The disconnected callback for `turbo-cable-stream-source` elements."}

So now that we know if we remove the element the subscription is unsubscribed,
how do we remove the stream element?

As mentioned before, the Turbo stream has a [remove event][] that can remove any
DOM identifier, not necessarily specific to Turbo connected elements.
Unfortunately, the `turbo_stream_from` helper doesn't currently include an ID or
parameter to specify one. Luckily it's pretty easy to modify ourselves by adding
our own version to a helper.

```ruby
  def turbo_stream_from(*streamables)
    tag.turbo_cable_stream_source(
      id:                   dom_id(*streamables),
      channel:              "Turbo::StreamsChannel",
      "signed-stream-name": Turbo::StreamsChannel.signed_stream_name(*streamables)
    )
  end
```
{: lines="3" caption="Customized version of the `turbo_stream_from` helper to
add ID support."}

With the stream identified we can remove and add streams as needed, which works
perfectly for us when a character is moving between two rooms.

```erb
<%= turbo_stream.remove previous_room %>
<%= turbo_stream.append("streams") do %>
  <%= turbo_stream_from current_room %>
<% end %>
```
{: caption="Removing and adding streams for the character moving between two
rooms."}

While we can append the streams to any element, we're appending to an element
identified by `streams`. This is simply to allow a central location to see what
streams the character is connected to.

While Turbo requires thinking about implementation a bit differently, it's
incredibly easy to use and should be much easier to maintain than a full React
application. I'm excited to see how Turbo is implemented over the next year.

[Action Cable]: https://guides.rubyonrails.org/action_cable_overview.html
[Hotwire]: https://hotwired.dev
[remove event]: https://turbo.hotwired.dev/reference/streams#remove
[stream events]: https://turbo.hotwired.dev/reference/streams
[turbo-rails]: https://github.com/hotwired/turbo-rails
