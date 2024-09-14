---
title: "Deploy Rails with Dokku"
image: "posts/2022-11-07/image@2x.png"
category: rails
subtitle: "Deploying a Rails application to DigitalOcean."
description: "Deploying a Rails application to DigitalOcean with Dokku."
permalink: /journal/deploy-rails-with-dokku/
modified_at: 2024-09-02
---

When Heroku [first announced the end of free plans][] I knew I'd need to figure
out where to move any projects soon, since spending $16-31 per side-project
would be rough. They have [since announced low-cost plans][], but that would
still run $13-19 per project. Comparing the prices to DigitalOcean, you can get
two to three Droplets with 1GB of memory each for the same price. Moving on from
Heroku was an easy decision based on pricing alone, even if I have been using it
nearly as long as I've been a Rails developer.

The next step was deciding how to manage the infrastructure and deploy
applications. And while solutions like Kubernetes, Terraform, and the like are
the go-to for a lot of people, it seemed like a lot to learn and manage for
personal projects.

Instead I explored Platform-as-a-Service, or PaaS, options to keep a similar
feel to Heroku. I chose [Dokku][] in the end because it's been around a while,
it's marketed as a mini-Heroku, and it satisfies all the requirements for
applications I run. The one pitfall is it's not built for running separate
servers in a cluster, but I'll cross that path if I ever have the need.
Although, you can run the database services on separate services if needed,
which should provide plenty of scaling capabilities.

## Installing Dokku

First we need to create a Droplet on [DigitalOcean][]. I'm using Ubuntu 22.04
and Dokku recommends at least 1GB of memory. Once the Droplet is live you should
be able to SSH in to get started installing Dokku.

**Note:** Even with 1GB of memory, I'd still recommend [creating a swap file][]
since I ran into build issues with Bundler due to limited free memory with the
services running.
{: class="note"}

```sh
ssh root@DROPLET_IP_ADDRESS
```

Install Dokku on the Droplet by following the [official installation
instructions][], which will take around 5-10 minutes to complete.

```sh
wget https://raw.githubusercontent.com/dokku/dokku/v0.33.3/bootstrap.sh
sudo DOKKU_TAG=v0.33.3 bash bootstrap.sh
rm bootstrap.sh
```

After the installation completes you can copy your local SSH key to add it as an
administrator in Dokku.

```sh
cat ~/.ssh/id_rsa.pub
```

Add your SSH key as an administrator to Dokku on the server.

```sh
echo "ssh-rsa ...key..." | dokku ssh-keys:add admin
```

## Creating an Application

For the rest of this article I'm going to be setting up an instance of
[Miroha][], a personal project of mine and the first project I migrated to use
Dokku. If you're setting up a project of your own, be sure to update the naming
for each command.

**Warning:** Miroha [switched to using Docker][] for deployment to prepare for
using [Kamal][] in production. If you'd like follow along using it, you need to
[clone this commit][].
{: class="warning"}

First on the server we'll create the application.

```sh
dokku apps:create miroha
```

And while we're still on the server via SSH, we can install the plug-ins we're
going to use since they have to run with `sudo`.

```sh
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git letsencrypt
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
```

We shouldn't need to SSH into the server anymore, so to continue the setup we're
going to install [the official client][]. It's a convenience wrapper around
[running remote commands with SSH][], which may be your solution if you're not
on macOS.

```sh
brew install dokku/repo/dokku
```

By default the client looks for a `dokku` remote in the Git repository, so we
can add that next. You can customize the name via `DOKKU_GIT_REMOTE` which can
be helpful if you are running more than one instance, such as staging and
production. See `brew info dokku` for all the options.

```sh
git remote add dokku dokku@DROPLET_IP_ADDRESS:miroha
```

We can verify our local configuration and the application remotely by retrieving
a report for the application. The information may look different compared to the
example below, but you are good to go as long as it succeeds.

```sh
$ dokku apps:report
=====> miroha app information
       App created at:                1665860238
       App deploy source:             miroha
       App deploy source metadata:    miroha
       App dir:                       /home/dokku/miroha
       App locked:                    false
```

## Creating the Databases

We already added the PostgreSQL and Redis plug-ins on the server, so it's one
command to create the database and one to link it to the application. To see all
of the commands for each plug-in you can run `dokku postgres` or `dokku redis`.

```sh
dokku postgres:create miroha_database
dokku postgres:link miroha_database miroha

dokku redis:create miroha_redis
dokku redis:link miroha_redis miroha
```

Since you are running all the services on a single instance you may want to
adjust the Redis memory settings. You can change the memory limit to 32
megabytes and the policy to evict the least frequently used key. To do so run
the `redis:connect` command with the database name and run the appropriate Redis
commands. See the default [redis.conf][] for more details on each setting.

```sh
dokku redis:connect miroha_redis

127.0.0.1:6379> CONFIG SET maxmemory 32mb
127.0.0.1:6379> CONFIG SET maxmemory-policy allkeys-lfu
```

For other Redis commands and settings see [the official Redis documentation][].

## Preparing for Deployment

We're almost ready for our first deployment, but there's a bit of configuration
we need to get through first.

### Setting the Default Branch

If you're using `main` or another branch name, you'll want to change the deploy
branch in Dokku. For a staging instance, I change it to be a `staging` branch to
be more explicit when pushing.

```sh
dokku git:set deploy-branch main
```

### Adding Buildpacks

If you are sticking with the default builder, [Herokuish][], then we need to add
a couple of buildpacks to build the application.

```sh
dokku buildpacks:add https://github.com/heroku/heroku-buildpack-nodejs
dokku buildpacks:add https://github.com/heroku/heroku-buildpack-ruby
```

Note that while the Ruby buildpack does have Node.js available, it doesn't
appear to cache the Yarn dependencies at the time of writing and results in a
much slower deployment. And if you add the Node.js buildpack the Ruby buildpack
will still install the dependencies a second time unless you disable it. Miroha
[uses an environment variable][] to alter the task.

### Setting the Master Key

Next we need to set the `RAILS_MASTER_KEY` environment variable to ensure the
application can boot. The `--no-restart` option argument is helpful to avoid
restarting the application when changing configuration.

```sh
dokku config:set --no-restart RAILS_MASTER_KEY="$(cat config/credentials/production.key)"
```

### Adding a Domain

Adding a domain is as simple as Heroku, but we need to remove the default local
domain. I remove the local domain due to running into issues with adding SSL,
which we'll get to next.

```sh
dokku domains:add miroha.com
dokku domains:remove miroha.miroha-web
```

You'll want to update the DNS for the domain to point to `DROPLET_IP_ADDRESS`,
if you don't the SSL certificate will fail.

### Enabling Automatic SSL

To use the Let's Encrypt plug-in, you first need to set an e-mail address for
requested certificates with.

```sh
dokku letsencrypt:set miroha email valid.email@example.com
```

With the e-mail set, we can enable the plug-in and add the automatic renewal
job. See [dokku-letsencrypt][] for more details.

```sh
dokku letsencrypt:enable
dokku letsencrypt:cron-job --add
```

**Tip:** Don't forget to enforce SSL in production. See the [ActionDispatch::SSL
documentation][].
{: class="note"}

### Scaling Processes

The last step to deploy is to scale up our clock and web processes so they will
start after deployment.

```sh
dokku ps:scale clock=1 web=1
```

## Deploying

To deploy the application it's as simple as pushing to Heroku. Be sure to use
the correct remote and branch names, if you picked different versions.

```sh
git push dokku main
```

If you don't have a `release` process set up you'll need to migrate and seed
your database as needed. Miroha [uses a release script][] to automatically run
migrations and allow it to be reset via an environment variable after each
deployment.

```sh
dokku run bundle exec rake db:migrate db:seed
```

If you don't see any error during the push or database migration, you should see
the application live at the domain you added. Congratulations!

## Bonus Improvements

### Enable YJIT

The new Ruby JIT compiler, YJIT, offers [substantial speed improvements][] over
the default compiler. The Ruby buildpack has built-in support, so we can enable
it by adding a `RUBY_YJIT_ENABLE` environment variable.

```sh
dokku config:set RUBY_YJIT_ENABLE="1"
```
{: caption="Enabling YJIT by default."}

You may want to run `dokku ps:rebuild` to ensure the change is picked up. Now
your application should have up to [a 17% speedup][] and use less memory.
Perhaps one of the easiest performance changes ever.

### Automatic Deployment with GitHub Actions

If you're looking to automatically deploy when you merge on GitHub, check out
[the official GitHub Action][] with the [simple example][] being the easiest
place to get started. If you have a staging branch, you may want to consider
enabling [force push][] and adding a post-deploy script to reset the database.

### Switching to Docker

If you'd prefer to switch from buildpacks to Docker, you'll need to clear the
buildpacks and the ports in the application. And if you're using a
`RAILS_MASTER_KEY` you'll need to add it as a build argument.

```sh
dokku docker-options:add build "--build-arg RAILS_MASTER_KEY"
```

See the [Dockerfile Deployment][] documentation for more information.

[ActionDispatch::SSL documentation]: https://api.rubyonrails.org/classes/ActionDispatch/SSL.html
[DigitalOcean]: https://m.do.co/c/a7c8d9fbaf7f
[Dockerfile Deployment]: https://dokku.com/docs/deployment/builders/dockerfiles/
[Dokku]: https://dokku.com
[Herokuish]: https://github.com/gliderlabs/herokuish
[Kamal]: https://kamal-deploy.org
[Miroha]: https://github.com/tristandunn/miroha
[a 17% speedup]: https://railsatscale.com/2023-12-04-ruby-3-3-s-yjit-faster-while-using-less-memory/
[clone this commit]: https://github.com/tristandunn/miroha/commit/d4885e70d0b3fca16ee0415369da79545b29aa22
[creating a swap file]: https://dokku.com/docs/getting-started/advanced-installation/#vms-with-less-than-1-gb-of-memory
[dokku-letsencrypt]: https://github.com/dokku/dokku-letsencrypt
[first announced the end of free plans]: https://blog.heroku.com/next-chapter
[force push]: https://github.com/dokku/github-action/blob/master/example-workflows/force-push.yaml
[official installation instructions]: https://dokku.com/docs/getting-started/installation/#installing-the-latest-stable-version
[redis.conf]: https://github.com/redis/redis/blob/unstable/redis.conf
[running remote commands with SSH]: https://dokku.com/docs/deployment/remote-commands/
[simple example]: https://github.com/dokku/github-action/blob/master/example-workflows/simple.yaml
[since announced low-cost plans]: https://blog.heroku.com/new-low-cost-plans
[substantial speed improvements]: https://speed.yjit.org
[switched to using Docker]: https://github.com/tristandunn/miroha/commit/e645310484741079ea4d8d3fbe4735b0033fe79c
[the official GitHub Action]: https://github.com/dokku/github-action
[the official Redis documentation]: https://redis.io/commands/
[the official client]: https://github.com/dokku/homebrew-repo
[uses a release script]: https://github.com/tristandunn/miroha/blob/fe88abbd0faf48931e95053b46fc20f97ff4c1a2/bin/release
[uses an environment variable]: https://github.com/tristandunn/miroha/blob/fe88abbd0faf48931e95053b46fc20f97ff4c1a2/lib/tasks/javascript.rake#L18-L28
