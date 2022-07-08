---
part: 3
title: "Deploying Jekyll to a VPS"
image: "posts/2015-05-31/image@2x.png"
footer: "series/deploying-jekyll-to-vps.html"
category: chef
subtitle: "Part 3: Deploying Remotely to Digital Ocean"
description: "Create a remote server, prepare Chef and Capistrano configuration,
and deploy to the public with a custom domain name."
redirect_from: /2015/05/31/deploying-jekyll-to-vps-part-3/
---

Continuing on [part two of the series][1] we'll create a remote server, deploy
to it, and set up a domain name to make it publicly accessible. We've already
done most of the hard work in the previous parts.

## Creating a Server

Create a [DigitalOcean][2] account if you don't already have one. You may have
to wait for account verification, but it normally doesn't take long.

### Creating a Droplet

Next we need to create a droplet, which is the DigitalOcean name for a server.
You should see the green "Create Droplet" button in the top right of your
dashboard. We'll have to provide details about the server. (DigitalOcean also
provides a more thorough [guide to creating your first server][3].)

#### Droplet Hostname

This name will be the machine's hostname, so we should use the website hostname
we plan to use.

#### Select Size

The $5 per month size should be fine for a static site, but it's up to you. If
you're planning to run any other services or background tasks then you may want
to consider a larger size. Note that you can adjust the size in the future, but
you may experience a bit of downtime depending on how you perform it.

#### Select Region

For the region you should pick whichever is closest to your target audience,
unless you plan on using a CDN such as [Fastly][4].

#### Available Settings

None of the available settings are necessary.

#### Select Image

The default machine image of `Ubuntu 14.04 x64` is fine and matches our local
Vagrant machine. If you're using a different image locally, try to match it to
ease testing of settings locally.

#### Add SSH Keys

And lastly you should add your public SSH key for root access instead of
receiving a plain text password via e-mail. If you don't already have an SSH
key, you can [follow this quick guide][5].

### Verification

The server will take a minute or so to boot. After you can verify it's running
by SSHing into it. The IP address for the server is on the detail page you see.
If you're using the SSH option it will prompt you to verify authenticity of the
host since it's your first time connecting, which you can do by entering "yes"
when prompted. If you're using the password option you'll need to provide the
password e-mailed to you.

```
ssh root@IP_ADDRESS
```
{: caption="SSHing into the remote server."}

## Configuring Chef

We'll need a SSH host for the new server, which is simple compared to the
Vagrant version. You can name it whatever you would like. The username will be
`root` and the hostname is the IP address of your server. Note that you can use
a domain name instead of an IP address once you configure the DNS.

```ruby
Host example        # Name.
  User root         # Username.
  Hostname 1.2.3.4  # Your droplet IP address.
```
{: caption="Adding a host to `~/.ssh/config` for the remote server."}

As for actual Chef configuration, all we need to do is duplicate the
`nodes/vagrant.json` file and name it the same as your SSH host. So if we
created an `example` host the file would be `nodes/example.json`.

## Configuring Capistrano

We created the base configuration in part two, but you probably want to update
the repository location, application name, and deployment location in the
`config/deploy.rb` file. See the `repo_url`, `deploy_to`, and `application`
variables.

To add a remote target we just need to specify the new remote server and which
branch we would like to deploy in a `config/deploy/remote.rb` file. You can name
the file whatever you would like, I just prefer seeing `local` and `remote`
within the command when deploying to keep it clear.

```ruby
# Define a web server, where "example" is the name our new SSH host and
# "deploy" is our server user created via Chef.
server "example", user: "deploy", roles: %w(web)

# Support deploying a specific branch, but default to the main branch.
#
# For example, to deploy the "css-fixes" branch:
#   BRANCH=css-fixes cap remote deploy
#
set :branch, ENV["BRANCH"] || "main"

# Optionally define custom configuration files, where the production version
# will overwrite the global version.
# set :configuration, "_config.yml,_config_production.yml"
```
{: caption="Defining the host, branch name, and custom configuration in
`config/deploy/remote.rb`."}

## Deploying to DigitalOcean

First we need to bootstrap Chef on the new server. Replace `example` with your
SSH host created above.

```
bundle exec knife solo bootstrap example
```
{: caption="Bootstrapping the remote server with Chef."}

If everything went as planned you should see the "404 Not Found" error when you
visit the server IP address. And now we can deploy the Jekyll website to the
remote server. If you named your Capistrano configuration file different than
`remote` then replace it below.

```
cap remote deploy
```
{: caption="Deploying to the remote server."}

Once complete you should see your website when you visit the server IP address
now. If you receive any errors ensure you changed the Capistrano variables
mentioned before in the `config/deploy.rb` file.

## Using a Domain Name

We can use [DNSimple][6] for creating and configuring a domain name. You can use
any service you prefer though. And if you already have a domain somewhere else,
you can also use [DigitalOcean for DNS][7].

First we need to [add a domain][8] to DNSimple, and register or transfer the
domain if necessary. If you already have a domain created elsewhere you'll just
need to update the nameservers to [point to DNSimple][9].

Once added we need to add the DNS records. Select "DNS" from the left menu, then
"Manage Records" under the "Custom Records" section. We're going to add two A
records. Select the "Add Record" dropdown, then the "A" option. For the first
record leave the name blank, enter the server IP address for the address, and
choose a TTL value. For the second provide the same values, but use `www` as the
name.

Depending on how fast your DNS updates, which could take hours, you should see
the deployed website on the domain name. You could also try using different DNS
nameservers that update faster, such as [Google's Public DNS][10].

## Summary

We now have all the components for deploying a Jekyll website to a remote server
and be available to the public. See the [jekyll-vps-server][11] repository for
the complete Chef source code, with the [part-3 branch][12] being specific to
this article. The website source code is available in the
[jekyll-vps-website][13] repository, with the [part-3 branch][14] being
relevant.

In the [next part][15] we'll add an asset pipeline and improve configuration for
serving the assets. [E-mail me](mailto:hello@tristandunn.com) if you have any
tips, comments, or questions.

[1]: /2015/05/05/deploying-jekyll-to-vps-part-2/
[2]: https://www.digitalocean.com
[3]: https://www.digitalocean.com/docs/droplets/how-to/create/
[4]: https://www.fastly.com
[5]: https://git-scm.com/book/en/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key
[6]: https://dnsimple.com/r/3edceb992aa254
[7]: https://docs.digitalocean.com/products/networking/dns/
[8]: https://dnsimple.com/tlds
[9]: https://support.dnsimple.com/articles/dnsimple-nameservers/
[10]: https://developers.google.com/speed/public-dns/docs/using
[11]: https://github.com/tristandunn/jekyll-vps-server
[12]: https://github.com/tristandunn/jekyll-vps-server/compare/part-2...part-3
[13]: https://github.com/tristandunn/jekyll-vps-website
[14]: https://github.com/tristandunn/jekyll-vps-website/compare/part-2...part-3
[15]: /2015/10/14/deploying-jekyll-to-vps-part-4/

*[TTL]: Time To Live
