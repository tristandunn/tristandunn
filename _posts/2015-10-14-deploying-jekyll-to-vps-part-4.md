---
part: 4
title: "Deploying Jekyll to a VPS"
image: "posts/2015-10-14/image@2x.png"
footer: "series/deploying-jekyll-to-vps.html"
category: chef
subtitle: "Part 4: Adding an Asset Pipeline"
description: "Add and configure an asset pipeline for Jekyll and add HTTP
caching for the assets."
redirect_from: /2015/10/14/deploying-jekyll-to-vps-part-4/
---

An asset pipeline is a key component of a web stack these days, since most
people don't want to manually run preprocessors, resize images, and concatenate
files. And while it may not be a big deal for a static website, depending on the
site, saving time for yourself and your user is never a bad idea.

## Adding the Asset Pipeline

The [jekyll-assets][1] library is a wonderful asset pipeline plug-in designed
for Jekyll. It supports a wide range of preprocessors, allows for easy asset
compression, can automatically resize images, and more. Plus it's built on top
of the popular [sprockets][2] library resulting in a rock solid foundation.

### Installation

First we'll need to add the `jekyll-assets` dependency to our `Gemfile` to
begin.

```ruby
source "https://rubygems.org"

gem "jekyll",        "2.5.3"
gem "jekyll-assets", "0.14.0"
gem "therubyracer",  "0.12.2"

group :development do
  gem "capistrano",         "3.4.0"
  gem "capistrano-bundler", "1.1.4"
  gem "capistrano-rbenv",   "2.0.3"
end
```
{: lines="4" caption="Adding a `jekyll-assets` dependency to our existing
`Gemfile`."}

And then we just need to load it as a Jekyll plug-in by creating a simple
`_plugins/assets.rb` file.

```ruby
require "jekyll-assets"
```
{: caption="Require the library as a plug-in in the `_plugins/assets.rb` file."}

### Configuration

The basic configuration is great, but we can do better. Let's simplify our Sass
with [Bourbon][3], enable CSS and JS compression to save our users time, and
cache the compiled files to save us time.

First let's add the `bourbon` library for Sass mixins and the `uglifier`
dependency for JavaScript compression to our `Gemfile`.

```ruby
source "https://rubygems.org"

gem "bourbon",       "4.2.5"
gem "jekyll",        "2.5.3"
gem "jekyll-assets", "0.14.0"
gem "therubyracer",  "0.12.2"
gem "uglifier",      "2.7.2"

group :development do
  gem "capistrano",         "3.4.0"
  gem "capistrano-bundler", "1.1.4"
  gem "capistrano-rbenv",   "2.0.3"
end
```
{: lines="3 7" caption="Adding a `bourbon` and `uglifier` dependencies to our
existing `Gemfile`."}

We need to require `jekyll-assets/bourbon` to enable Bourbon. Note that there is
mention of removing this in a future version of `jekyll-assets`.

```ruby
require "jekyll-assets"
require "jekyll-assets/bourbon"
```
{: caption="Adding Bourbon to the `_plugins/assets.rb` file."}

Now we can add our asset configuration to our Jekyll `_config.yml` file to
enable caching and compression.

```yaml
assets:
  cache: true
  js_compressor: uglifier
  css_compressor: sass

# ...
```
{: caption="Adding asset configuration to the `_config.yml` file."}

If you do cache the assets you will want to add `.jekyll-assets-cache` to your
`.gitignore` file.

### Usage

A jazzy asset pipeline isn't much use if it's not in use. The [README][4]
provides a great explanation of the tags and filters available to us. But for a
quick explanation, let's say we have the following asset files.

* `_assets/images/logo.png` — Our website logo.
* `_assets/javascripts/newsletter.js` — Custom JavaScript for our newsletter
  form.
* `_assets/stylesheets/application.scss` — The global CSS for our site.

We can render tags for them in a template with the new Liquid tags.

```liquid
---
title: Assets Example
permalink: /assets-example/
---
<html>
<head>
  {{ "{% stylesheet application " }}%}
</head>
<body>

<header>
  {{ "{% image logo.png " }}%}
</header>

{{ "{% javascript newsletter " }}%}

</body>
</html>
```
{: caption="A short example Liquid template with asset tags in an
`assets-example.md` file."}

### Relative URLs

By default the pipeline will prepend `/assets/` to the asset path, but there may
be certain cases when an absolute URL is neccessary. We can change the base URL
for assets in the Jekyll configuration. And this is useful if you're using a
separate domain or CDN for your assets.

```yaml
assets:
  baseurl: "http://example.com/assets/"

# ...
```
{: caption="Adding an asset base URL to the Jekyll configuration."}

While this is an easy change, we don't want to try loading our local assets from
our production server. The handy `configuration` setting we added in the [second
part of the series][5] allows us to add the setting to `_config_production.yml`
and use it when deploying remotely.

```ruby
# ...

# Define a custom configuration file, where the production version will
# overwrite the global version.
set :configuration, "_config.yml,_config_production.yml"
```
{: caption="Defining custom configuration in `config/deploy/remote.rb`."}

## Improving HTTP Caching

While the asset pipeline will help minify our CSS and JS file sizes, we can also
add [gzip][6] compression and improve the HTTP caching for all assets. Note that
since any asset URL will contain a digest making it unique, we can cache them
far into the future.

```nginx
server {
  root /var/www/example.com/current/_site;

  location ~ "^/assets/" {
    # Enable gzip compression.
    gzip_vary on;
    gzip_static on;

    # Leverage browser caching.
    add_header ETag "";
    add_header Expires "Thu, 31 Dec 2037 23:55:55 GMT";
    add_header Cache-Control "public, max-age=315360000";
  }
}
```
{: lines="4-13" caption="Improving asset caching in the
`site-cookbooks/server/templates/default/example.nginx` file."}

For any further performance, the Google [PageSpeed Tools][7] can be helpful.

## Summary

We now have a full asset pipeline complete with performance improvements, which
is sure to make our website insanely fast to load. See the
[jekyll-vps-server][8] repository for the complete Chef source code, with the
[part-4 branch][9] being specific to this article. The website source code is
available in the [jekyll-vps-website][10] repository, with the [part-4
branch][11] being relevant.

In the [next part][12] we'll switch to be HTTPS only. [E-mail
me](mailto:hello@tristandunn.com) if you have any tips, comments, or questions.

[1]: https://github.com/envygeeks/jekyll-assets
[2]: https://github.com/sstephenson/sprockets
[3]: https://bourbon.io
[4]: https://github.com/envygeeks/jekyll-assets/tree/v1.0-legacy#jekyllassets
[5]: /2015/05/05/deploying-jekyll-to-vps-part-2/
[6]: https://en.wikipedia.org/wiki/Gzip
[7]: https://developers.google.com/speed/pagespeed/
[8]: https://github.com/tristandunn/jekyll-vps-server
[9]: https://github.com/tristandunn/jekyll-vps-server/compare/part-3...part-4
[10]: https://github.com/tristandunn/jekyll-vps-website
[11]: https://github.com/tristandunn/jekyll-vps-website/compare/part-3...part-4
[12]: /2016/04/30/deploying-jekyll-to-vps-part-5/
