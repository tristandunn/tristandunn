---
title: "Jekyll with TailwindCSS in JIT Mode"
image: "posts/2021-09-10/image@2x.png"
category: jekyll
description: "How to use TailwindCSS in JIT mode with a Jekyll website."
permalink: /journal/jekyll-with-tailwindcss-jit-mode/
modified_at: 2021-09-11
---

These fixes are now included in the [jekyll-postcss][] library.
{: class="outdated"}

It's been possible to use TailwindCSS in Jekyll via [jekyll-postcss][] for a
while, but it can be incredibly slow to generate, especially when working
locally. In April 2021 TailwindCSS released a new JIT (just-in-time) engine that
drastically speeds up generation. There are currently a couple of issues in
`jekyll-postcss` that prevents JIT mode from being enabled, but fortunately
there are simple fixes we can implement.

> Tailwind CSS v2.1 introduces a new just-in-time compiler for Tailwind CSS that
> generates your styles on-demand as you author your templates instead of
> generating everything in advance at initial build time.

## No Such File or Directory

The first issue is the PostCSS generation fails to run at all due to the
following error, first reported in the [jekyll-postcss#22][] issue:

```text
PostCSS Error!

Error: ENOENT: no such file or directory, stat 'stdin'
```

In the issue [ENT8R](https://github.com/ENT8R) provides [a comment][] explaining
that TailwindCSS is expecting a value to be a file path but is receiving
`stdin`. Since `stdin` is not actually a path it throws an error.

You can fix it by creating an `stdin` file in the root directory of the Jekyll
project. It doesn't need to contain anything, it just needs to exist. And don't
forget to exclude the file in the Jekyll configuration.

## Forcing the CSS to Update

While everything is running now, if you add a completely new class to an HTML
file you'll notice it will have no effect. This is because `jekyll-postcss` is
caching the generated CSS based on the input. While your CSS hasn't changed, the
needed CSS has. And until PostCSS is triggered then JIT mode can't determine a
new CSS class is needed and add it to the generated CSS.

The quick fix here is to monkey patch `jekyll-postcss` to pretend there's always
a cache miss, essentially disabling caching:

```ruby
# frozen_string_literal: true

module Jekyll
  module Converters
    class PostCss < Converter
      private

      def cache_miss
        [true]
      end
    end
  end
end
```
{: caption="Adding a `_plugins/postcss.rb` file to disable caching."}

You can verify the fix by adding a TailwindCSS class that's not used anywhere,
perhaps an unused text color such as `text-indigo-50`. If the color changes then
you're successfully using JIT mode in Jekyll!

## The Future

~~Today I opened [a pull request][] for `jekyll-postcss` to fix the `stdin`
issue and add a `cache` option to make it easier to disable the caching.
Hopefully these quick fixes won't be needed in the near future.~~

Thanks to [Mitchell Hanberg][] for merging and releasing the fixes in less than
24 hours.

[jekyll-postcss]: https://github.com/mhanberg/jekyll-postcss
[jekyll-postcss#22]: https://github.com/mhanberg/jekyll-postcss/issues/22
[a comment]: https://github.com/mhanberg/jekyll-postcss/issues/22#issuecomment-903290240
[standard input]: https://en.wikipedia.org/wiki/Standard_streams
[a pull request]: https://github.com/mhanberg/jekyll-postcss/pull/32
[Mitchell Hanberg]: https://github.com/mhanberg
