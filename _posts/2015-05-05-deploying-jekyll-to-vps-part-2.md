---
part: 2
title: "Deploying Jekyll to a VPS"
image: "posts/2015-05-05/image@2x.png"
footer: "series/deploying-jekyll-to-vps.html"
category: chef
subtitle: "Part 2: Security, Monitoring, and Local Deployment"
description: "Increase server security, add service monitoring, and configure
Capistrano for deploying to the local server. "
redirect_from: /2015/05/05/deploying-jekyll-to-vps-part-2/
---

Continuing on [part one of the series][1] we'll increase the server security by
disabling password authentication for SSH, add [Monit][2] to oversee services,
and deploy to the local Vagrant server with [Capistrano][3].

## SSH Security

It's generally recommended that you disable password authentication for SSH to
help prevent common brute force attacks. You could also add IP addresses to an
allowlist, but key authentication is reasonable enough for us.

We already created and authorized a `deploy` user in the previous article. If
you're already deploying remotely and using [DigitalOcean][4] you should have
authorized your key for the root user, or received a root password. If you are
using another provider, please ensure you have authorized your key or have a
**strong** root password.

To disable password authentication we can add the [sshd cookbook][5] and
customize SSH options in the node file. We just need to add it to our `Cheffile`
and install it with `bundle exec librarian-chef install`.

```ruby
site "http://community.opscode.com/api/v1"

cookbook "nginx"
cookbook "rbenv"
cookbook "sshd"
```
{: lines="5" caption="Adding the sshd cookbook dependency the `Cheffile`."}

Now we can add the recipe to the run list and disable password authentication.
*Note that I'm excluding the other settings from the previous articles.*

```json
{
  "run_list" : [
    "recipe[user]",
    "recipe[ruby]",
    "recipe[server]",
    "recipe[sshd]"
  ],

  "sshd" : {
    "sshd_config" : {
      "PasswordAuthentication" : "no"
    }
  }
}
```
{: lines="6 9-13" caption="Adding attributes to `nodes/vagrant.json` for the
sshd recipe and settings."}

And we can run the new recipe with the standard `bundle exec knife solo cook
vagrant` process.

We can confirm that password authentication is not allowed by attempting to
authentication with a password using `ssh deploy:@vagrant`. If all went as
planned we should see a `Permission denied (publickey).` message.

## Monitoring

While a Jekyll website may not be mission critical, monitoring is still
important to keep it functioning when the unexpected happens. We're going to use
[Monit][2] for basic monitoring, a simple and popular solution for system
monitoring and error recovery.

We can of course use an existing cookbook, the [monit-ng cookbook][6], to add
some basic checks. To start add it to the `Cheffile` and install it with `bundle
exec librarian-chef install`.

```ruby
site "http://community.opscode.com/api/v1"

cookbook "monit-ng"
cookbook "nginx"
cookbook "rbenv"
cookbook "sshd"
```
{: lines="3" caption="Adding the monit-ng cookbook dependency the `Cheffile`."}

First we need to define our custom cookbook name and dependency.

```ruby
name    "monit"
depends "monit-ng"
```
{: caption="Creating the `site-cookbooks/monit/metadata.rb` file."}

And the default recipe will define basic process ID checks for the `nginx` and
`sshd` services.

```ruby
include_recipe "monit-ng::default"

monit_check "nginx" do
  stop     "/etc/init.d/nginx stop"
  start    "/etc/init.d/nginx start"
  check_id "/var/run/nginx.pid"
end

monit_check "sshd" do
  stop     "/etc/init.d/ssh stop"
  start    "/etc/init.d/ssh start"
  check_id "/var/run/sshd.pid"
end
```
{: caption="Defining checks in the `site-cookbooks/monit/recipes/default.rb`
file."}

And we need to add our new recipe to the run list. We're running it last to
ensure the processes we're monitoring are available.

```json
{
  "run_list" : [
    "recipe[user]",
    "recipe[ruby]",
    "recipe[server]",
    "recipe[sshd]",
    "recipe[monit]"
  ]
}
```
{: lines="7" caption="Adding monit recipe to `nodes/vagrant.json`."}

After running the recurring `bundle exec knife solo cook vagrant` command to
install, we can double check that it's monitoring properly. Just SSH into the
server to stop the web server with `sudo /etc/init.d/nginx stop` and it should
restart automatically within about 30 seconds. The current status of monitored
services are available by running `sudo monit status`.

## Deploying to Vagrant

We of course need a Jekyll website to be able to deploy. If you don't already
have one, you can generate one by running `jekyll new jekyll-vps-website`, with
the last argument being whatever name you would like.

Next we need to install Capistrano and a couple of dependencies. We also add
`jekyll` to install it on the server and `therubyracer` for a JavaScript
environment. At the time of writing Jekyll requires a JS environment for the
CoffeeScript dependency, but it will no longer be a required dependency in the
future.

```ruby
gem "jekyll",       "2.5.3"
gem "therubyracer", "0.12.2"

group :development do
  gem "capistrano",         "3.4.0"
  gem "capistrano-bundler", "1.1.4"
  gem "capistrano-rbenv",   "2.0.3"
end
```
{: caption="Adding Capistrano dependencies `Gemfile`."}

After running `bundle install` we can generate the Capistrano structure,
including our local stage, with `bundle exec cap install STAGES=local`.

Our other dependencies aren't included by default, so we'll require them in the
`Capfile`.

```ruby
require "capistrano/setup"
require "capistrano/deploy"

require "capistrano/bundle"
require "capistrano/rbenv"
```
{: caption="Setting up the base `Capfile` for Capistrano."}

We should also exclude some files and folders from the Jekyll output to prevent
them from being publicly accessible in the future.

```yaml
# ...

exclude:
  - Capfile
  - Gemfile
  - Gemfile.lock
  - config
```
{: caption="Adding exclusions to the `_config.yml` for Jekyll."}

Now we can customize the `config/deploy.rb` file with our custom settings and
actions for building and deploying the website. It's a decent chunk of code, so
I explain each section in comments.

```ruby
# Lock the Capistrano version to ensure we're running the version we expect.
lock "3.4.0"

# Application name and deployment location.
#
# The repository URL is not used locally, so no need to change it yet. The
# deployment location and application name are from the name used in part one
# of the series, so be sure to update if you used a different name.
set :repo_url,    "https://github.com/tristandunn/jekyll-vps-website.git"
set :deploy_to,   "/var/www/example.com"
set :application, "example"

# Ensure bundler runs for the web role.
set :bundle_roles, :web

# Location and settings for rbenv environment.
set :rbenv_type,        :system
set :rbenv_ruby,        "2.1.5"
set :rbenv_roles,       :all
set :rbenv_map_bins,    %w(bundle gem rake ruby)
set :rbenv_custom_path, "/opt/rbenv"

# Don't keep any previous releases.
set :keep_releases, 1

# Avoid UTF-8 issues when building Jekyll.
set :default_env, { "LC_ALL" => "en_US.UTF-8" }

# Define a custom Jekyll build task and run it before publishing the website. It
# allows for a custom configuration setting per environment, which is helpful
# for customizing settings in production.
namespace :deploy do
  desc "Build the website with Jekyll"
  task :build do
    on roles(:web) do
      within release_path do
        execute :bundle, "exec", "jekyll", "build", "--config",
          fetch(:configuration, "_config.yml")
      end
    end
  end

  before :publishing, :build
end

# Don't log revisions.
Rake::Task["deploy:log_revision"].clear_actions
```
{: caption="Adding the core settings, actions, and customization in
`config/deploy.rb`."}

Instead of having to commit to a branch, push to a remote, and then deploy a
branch on a local server we're just going to package and upload the directory
content to the local server. It allows you to test changes in a "production"
environment much faster. To do so we need to define a custom strategy. It's a
rather large class so I've commented the code heavily.

```ruby
module FileStrategy
  # Pretend we don't have a repository cache.
  def test
    false
  end

  # Ensure the repository path exists.
  def check
    context.execute :mkdir, "-p", repo_path
  end

  # Pretend we've cloned the repository.
  def clone
    true
  end

  # Create and upload a package of the local directory as an update.
  def update
    # Ensure a local `tmp` directory exists.
    `mkdir -p #{File.dirname(path)}`

    # Package the local directory, ignoring unnecessary files.
    `tar -zcf #{path} --exclude .git --exclude _site --exclude tmp .`

    # Upload the package to the server.
    context.upload! path, "/#{path}"

    # Remove the package locally.
    `rm #{path}`
  end

  # Extract the uploaded package to the release path and remove.
  def release
    # Ensure the release directory exists on the server.
    context.execute :mkdir, "-p", release_path

    # Extract the uploaded package to the release directory.
    context.execute :tar, "-xmf" "/#{path}", "-C", release_path

    # Remove the package from the server.
    context.execute :rm, "/#{path}"
  end

  # Use the latest repository SHA as the revision.
  def fetch_revision
    `git log --pretty=format:'%h' -n 1 HEAD`
  end

  protected

  # Helper method for the directory package path.
  def path
    "tmp/#{fetch(:application)}.tar.gz"
  end
end
```
{: caption="Creating a custom deployment strategy in
`config/deploy/local/file_strategy.rb`."}

Lastly we'll update our local stage to define the server, use the file strategy
for deployment, and optionally include custom Jekyll configuration.

```ruby
# Require our custom deployment strategy.
require "./config/deploy/local/file_strategy"

# Define a web server, where "vagrant" is our local SSH host and "deploy" is our
# server user created in part one.
server "vagrant", user: "deploy", roles: %w(web)

# Set our custom strategy.
set :git_strategy, FileStrategy

# Optionally define custom configuration files, where the staging version will
# overwrite the global version.
# set :configuration, "_config.yml,_config_staging.yml"
```
{: caption="Defining the host, deployment strategy, and custom configuration in
`config/deploy/local.rb`."}

We should now be able to deploy by running `cap local deploy`. It will take a
minute the first time as it needs to install dependencies. After the website
generation completes you should see your website at
[localhost:8080](http://localhost:8080).

## Summary

We now how the minimal components needed to deploy a Jekyll website to a Vagrant
box. See the [jekyll-vps-server][7] repository for the complete Chef source
code, with the [part-2 branch][8] being specific to this article. The website
source code is available in the [jekyll-vps-website][9] repository, with the
[part-2 branch][10] being relevant.

In the [next part][11] we'll create and deploy to a [DigitalOcean][4] server to
have a production version available. [E-mail me](mailto:hello@tristandunn.com)
if you have any tips, comments, or questions.

[1]: /2014/12/15/deploying-jekyll-to-vps-part-1/
[2]: https://mmonit.com/monit/
[3]: https://capistranorb.com
[4]: https://www.digitalocean.com
[5]: https://supermarket.chef.io/cookbooks/sshd
[6]: https://supermarket.chef.io/cookbooks/monit-ng
[7]: https://github.com/tristandunn/jekyll-vps-server
[8]: https://github.com/tristandunn/jekyll-vps-server/compare/part-1...part-2
[9]: https://github.com/tristandunn/jekyll-vps-website
[10]: https://github.com/tristandunn/jekyll-vps-website/compare/part-1...part-2
[11]: /2015/05/31/deploying-jekyll-to-vps-part-3/

*[SSH]: Secure Shell
