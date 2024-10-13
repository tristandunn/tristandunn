---
title: "Untitled, a Rails Template"
category: rails
subtitle: "Set up and deploy a new Rails application with Kamal."
description: "A full-featured Rails template with CI and CD to kickstart your next project."
permalink: /journal/rails-8-template-with-kamal/
---

[Untitled][] is my Rails template that I've be maintaining and keeping
up-to-date for over four years now. With the [release of Rails 8][] including
[Kamal][] I wanted to document the full setup process, since continuous and
local deployments require a bit more work beyond cloning the repository.

## Preparation

To start we're going to customize the deployment configuration, set up the
GitHub container registry, and set up a few of the required secrets.

### Domains

The template is set up to deploy to staging and production domains, so let's
customize them in the deployment configuration files.

```yaml
proxy:
  ssl: true
  host: untitled-staging.tristandunn.com
  healthcheck:
    path: /health
```
{: lines="3" caption="Setting a staging domain in the `config/deploy.yml` file."
}

Other destinations in Kamal inherit from the base deployment configuration, so
we only need to set the production domain here.

```yaml
proxy:
  host: untitled.tristandunn.com
```
{: lines="2" caption="Setting a production domain in the
`config/deploy.production.yml` file." }

### Container Registry

By default Kamal uses the Docker container registry, but I'd prefer to use
GitHub instead. First you need to [create a token][] with the `write:packages`
scope. The token goes in our `.env` file under the `KAMAL_REGISTRY_PASSWORD`
variable.

```sh
KAMAL_REGISTRY_PASSWORD="GITHUB_TOKEN"
```
{: caption="Setting the registry password in the `.env` file." }

### Secrets

We also need a base secret key for Rails, which you can generate by running
the `bin/rails secret` command and adding it to the same file.

```sh
KAMAL_REGISTRY_PASSWORD="GITHUB_TOKEN"
SECRET_KEY_BASE="RANDOM_SECRET"
```
{: lines="2" caption="Setting the secret key base in the `.env` file." }

That should be enough configuration for you to deploy to a staging server.

## Local Deployment

We're going to start by deploying from a local machine. You'll need a server to
deploy to, which can be any server capable of running Docker. I'm using
[DigitalOcean][] since I was [deploying with Dokku][] there already.

**Note:** The link to DigitalOcean is a referral link which will give you $200
in credit over 60 days and if you eventually spend $25 it will give me $25 in
credit.
{: class="note"}

### Creating and Configuring a Server

For testing I'm using a server with 1 GB of memory at $6/month, but if you're
planning to have a staging and production deployment with real load you'll
probably want at least 2 GB of memory to be safe. If you're not familiar with
creating a server on DigitalOcean, see [the quickstart guide][] for details.

After the server is created you'll need to copy the IP address and add it to the
`config/deploy.yml` file for the web server.

```yaml
# Deploy to these servers.
servers:
  web:
    - 192.168.0.1
```
{: caption="Updating the IP address for the web server in the
`config/deploy.yml` file." }

You'll also want to add DNS entries for your staging and production domains to
point to the same IP address.

### Deploying to Staging

If you have Docker running, we can set up our first Kamal application which will
install Docker on the remote server and deploy the application to the staging
host.

```sh
$ eval $(cat .env) bin/kamal setup
```

Note that we're evaluating the secrets in the `.env` file to make them available
to Kamal. See [the environment variable documentation][] and how to [switch to a
secret helper][] for more information.

### Litestream

[Litestream][] continuously streams SQLite changes to fully replica the
database. It's basically a drop-in backup solution with [litestream-ruby][]
running inside the Puma server. And it works with an assortment of storage
providers, including the S3 compatible [Spaces from DigitalOcean][] that we're
going to use.

After [creating a bucket][] take note of the origin endpoint. To access the
bucket we need to [create an access key][] which will provide an access key and
secret. We then add all three to the `.env` file.

```sh
KAMAL_REGISTRY_PASSWORD="GITHUB_TOKEN"
LITESTREAM_ACCESS_KEY_ID="SPACES_ACCESS_KEY"
LITESTREAM_REPLICA_HOST="SPACES_HOSTNAME"
LITESTREAM_SECRET_ACCESS_KEY="SPACES_ACCESS_KEY"
SECRET_KEY_BASE="RANDOM_SECRET"
```
{: lines="2-4" caption="Setting the Litestream options in the `.env` file." }

Also, be sure to not include `https://` in the hostname.

### Deploying to Production

We're now ready to deploy to production. Since we're using the same server, we
can use the deploy command instead but provide production as the destination.

```sh
$ eval $(cat .env) bin/kamal deploy --destination=production
```

## Continuous Deployment

- SSH private key.
- GitHub Actions access to package.
- GitHub secrets.

## Improvements

- Litestream dashboard.
- Job runner.
- CD for staging from any push.
- Automatic review applications. Create on open and destroy on close.

{% raw %}
```yaml
on:
  pull_request:
    types:
      - opened
      - reopened

env:
  GITHUB_PR_NUMBER: ${{ github.event.pull_request.number }}

jobs:
  Deploy:
    - name: Create configuration
      run: |
        echo "proxy:\n  host: pr-$GITHUB_PR_NUMBER.tristandunn.com" > config/deploy.$GITHUB_PR_NUMBER.yml
    - name: Deploy the application
      shell: bash
      env:
        ${{ insert }}: ${{ secrets }}
        DOCKER_BUILDKIT: 1
        KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
      run: bin/kamal deploy --destination=$GITHUB_PR_NUMBER
```
{% endraw %}

{% raw %}
```yaml
on:
  pull_request:
    types:
      - closed

env:
  GITHUB_PR_NUMBER: ${{ github.event.pull_request.number }}

jobs:
  Deploy:
    - name: Create configuration
      run: |
        echo "proxy:\n  host: pr-$GITHUB_PR_NUMBER.tristandunn.com" > config/deploy.$GITHUB_PR_NUMBER.yml
    - name: Deploy the application
      shell: bash
      env:
        ${{ insert }}: ${{ secrets }}
        DOCKER_BUILDKIT: 1
        KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
      run: bin/kamal remove --destination=$GITHUB_PR_NUMBER
```
{% endraw %}

[DigitalOcean]: https://m.do.co/c/a7c8d9fbaf7f
[Kamal]: https://kamal-deploy.org
[Litestream]: https://litestream.io
[Spaces from DigitalOcean]: https://www.digitalocean.com/products/spaces
[Untitled]: https://github.com/tristandunn/untitled
[create an access key]: https://cloud.digitalocean.com/account/api/spaces
[create a token]: https://github.com/settings/tokens/new
[creating a bucket]: https://cloud.digitalocean.com/spaces/new
[deploying with Dokku]: /journal/deploy-rails-with-dokku/
[litestream-ruby]: https://github.com/fractaledmind/litestream-ruby
[release of Rails 8]: https://rubyonrails.org/2024/9/27/rails-8-beta1-no-paas-required
[switch to a secret helper]: https://kamal-deploy.org/docs/commands/secrets/
[the environment variable documentation]: https://kamal-deploy.org/docs/configuration/environment-variables/
[the quickstart guide]: https://docs.digitalocean.com/products/droplets/getting-started/quickstart/
