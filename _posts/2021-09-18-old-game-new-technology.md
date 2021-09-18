---
draft: true
title: "Old Game, New Technology"
image: "posts/2021-09-18/image@2x.png"
category: miroha
subtitle: "Building my 24 year old game for the modern web."
description: "Building my 24 year old game for the modern web."
permalink: /journal/old-game-new-technology/
twitter_card: summary_large_image
---

I was first attracted to web development in 1997 to build a skateboarding
website on [GeoCities][]. Using GeoCities ended up being the gateway to my
career as a software engineer. Along the way though the real passion that helped
me learn to program was building video games, specifically a role-playing game.

Most of high school I had a spare notebook that I'd write code in during class
to bring home and transcribe into Visual Basic 6. Figuring out an optimal method
for the client and server to communicate, working out how to calculate the
experience needed for each level, or how monsters would fight back. All in my
notebook.

Learning Visual Basic 6 lead to my first job as a student worker writing ASP. I
had a lot of free time there which lead to me learning PHP, JavaScript, and CSS.
At each phase I'd adapt and improve the game using the new technology I was
learning. In 2009 I used the source code of my Ruby on Rails version of the game
to apply at [thoughtbot][] and it's the reason I created my [pusher-fake][]
library almost ten years ago.

Over the years the game became a test bed more and more for me to learn about
new technologies. While it's been great for my career, the fun has faded over
the years and it typically meant the internet never even saw the game. I want
that to change that now, but want to explore the history a bit first.

## The Past

The game has bounced around between different technologies over the years, but
that also included different names, stories, and gameplay changes.

### The Fallen Dragons

I believe my friend and I first called the game Aurora, but we couldn't get a
good domain for it and settled on The Fallen Dragons instead. The Fallen Dragons
was a client-server game written in Visual Basic 6, inspired by [Realms of
Kaos][]. I learned all sorts of new concepts while writing a client and server
including a lot about networking, since I was running the server on my computer
at home.

Probably the most fun of all the games, since everything was new and exciting. I
still remember the random person who downloaded our client and played off and on
for a week. They said they were from Russia and asked us to make custom in-game
items for them. That was a fun week. Other than that no one beyond a couple of
close friends ever played the game.

### Monster Massacre

Monster Massacre was my first web-based version, written in PHP. A
point-and-click game where you had a stamina system that refreshed over time to
limit how often you could fight. There were probably hundreds, if not thousands,
of similar games at the time.

It had a slightly bigger player base, with friends of friends playing it over
the span of a couple of months. This was my first exposure to web security,
since my friends would often try to hack it. Such as discovering they could
manually run the periodic script to replenish stamina that I left it exposed to
the web. That was a fun discovery since they didn't readily tell me and used it
to level up faster.

The source code of the later versions are still sitting around in my backups. I
laugh a little every time I go back and look at the horrible code, since they're
from around 2005.

### Miroha

I named the first Ruby on Rails version Miroha, which I have zero recollection
of how I came up with the name. I registered the domain nearly 16 years ago and
the name certainly sounds more legitimate than Monster Massacre.

I don't recall if anyone ever played it other than a friend or two, but it's
been my main test bed for new technology since it started. Over the years I've
used long-polling, experimented with server-sent events, wrote my own WebSockets
server in Node.js, briefly used Pusher which spawned [an open source library][],
tried out React, explored new CSS techniques like `flexbox` and Tailwind CSS,
learned [how to use Turbo Rails][], and *so much more*.

## The Future

While the old iterations have been fun, my goal for the future is to actively
work on Miroha instead of it being a test bed for technology experiments. And
I'd be incredibly excited if it's playable online again, instead of locally.

### Open Source

The first step is to start [an open source version of Miroha][]. While this
could lead to some accountability, it'll at least avoid hiding the work, allow
others to learn from it, and allow the less frequent experiments be a source of
examples for other people exploring the same new technologies.

### Deployment

The second step is to deploy Miroha publicly on Heroku. This will allow people
to actually play the game and it'll make it easier for other people deploying
their own versions as well. Being able to play with other people again might be
the most exciting part, plus hopefully collecting feedback from them on how to
improve the game.

### Writing

Third is writing a story for the game, which is generally what makes or breaks a
role-playing game. The players need to learn the history, become part of the
story, and have it help drive how they play. This will be the hardest part of
making the game, but has the added bonus of helping me improve my writing
skills.

### Documentation

Fourth is documenting the process that goes into building a game. You could look
at the changes to see what the result is, but how were product decisions made,
what goes into planning the story, or how do you manage an open source game that
anyone can suggest changes to. While it'll be nice to share the learning
experiences with others, having a record for myself will be great too.

## The Present

While open sourcing the new version of the game is a start, these are pretty
lofty goals. Even with trying to stay positive, I know all these future goals
will be difficult to complete. At the time of writing I'll consider this a
success if the game is playable online and at least 10 people end up playing it.
A rather small target, but it would have been an insane accomplishment to me in
high school.

[GeoCities]: https://en.wikipedia.org/wiki/Yahoo!_GeoCities
[thoughtbot]: https://thoughtbot.com
[pusher-fake]: https://github.com/tristandunn/pusher-fake
[Realms of Kaos]: https://realmsofkaos.fandom.com/wiki/Realms_of_Kaos_Wiki
[an open source library]: https://github.com/tristandunn/pusher-fake
[how to use Turbo Rails]: /journal/switching-streams-turbo-rails/
[an open source version of Miroha]: https://github.com/tristandunn/miroha
