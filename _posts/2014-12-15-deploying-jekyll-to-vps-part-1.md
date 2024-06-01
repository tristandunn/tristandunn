---
part: 1
title: "Deploying Jekyll to a VPS"
image: "posts/2014-12-15/image@2x.png"
footer: "series/deploying-jekyll-to-vps.html"
category: chef
subtitle: "Part 1: Setting Up a Local Vagrant Server with Chef"
description: "A step-by-step guide to setting up a local Vagrant server, with
custom and existing Chef recipes, for testing configuration and deployment."
redirect_from: /2014/12/15/deploying-jekyll-to-vps-part-1/
---

[Jekyll][1], a static site generator, has become a common solution for websites.
While [GitHub Pages][2] offers free hosting, customization is somewhat limited.

Deploying to Heroku is an option for customization, but is a bit much for a
static website. And while we can deploy to GitHub if we pre-compile, we are
still limited to what the server can do. Whereas with a VPS from
[DigitalOcean][3], for as little as $5 per month, we can customize everything.

Managing a sever by hand is annoying, scary, and a hassle. Instead we can use
[Chef][4] to manage the server. We'll be going through the process I used to
deploy this website, starting with creating a local [Vagrant][5] server.

## Vagrant

![Vagrant logo.](/images/posts/2014-12-15/vagrant.jpg){: width="128"
height="128" class="float-right mb-6 ml-6"
srcset="/images/posts/2014-12-15/vagrant.jpg 1x,
/images/posts/2014-12-15/vagrant@2x.jpg 2x" style="max-width: 128px;"}
Vagrant allows us to "create and configure lightweight, reproducible, and
portable development environments." Being able to work offline or without a paid
server is nice, but the ability to try changes with no harm is the biggest
advantage. And that's the main reason we're starting with it.

### Installation

First we need to [download and install Vagrant][6]. And we'll be using
[VirtualBox][7] as the virtual machine provider. [Other providers][8] are also
supported though, such as VMware.

### Configuration

A `Vagrantfile` describes and configures the machine, which uses Ruby and is
[well documented][9]. We'll be initializing it with a `hashicorp/precise64` box,
a standard Ubuntu 12.04 LTS 64-bit box. Other operating systems are available on
[vagrantbox.es][10].

```sh
$ vagrant init hashicorp/precise64

A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
```
{: caption="Initializing Vagrant with a 64-bit Ubuntu box in the server
directory."}

We can simplify the generated file to the bare necessities, the box and the
memory available. We're going to use a 512MB machine in production, so we can
match it locally.

```ruby
Vagrant.configure("2") do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "hashicorp/precise64"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  config.vm.provider "virtualbox" do |box|
    box.memory = 512
  end
end
```
{: caption="Simplifying the `Vagrantfile` to box and memory configuration."}

To ensure we have everything configured correctly we can boot the server with
`vagrant up` and SSH into it with `vagrant ssh`.

## Chef

![Chef logo.](/images/posts/2014-12-15/chef.jpg){: width="128" height="126"
class="float-right mb-6 ml-6" srcset="/images/posts/2014-12-15/chef.jpg 1x,
/images/posts/2014-12-15/chef@2x.jpg 2x" style="max-width: 128px;"}
Next we need to setup and configure Chef, which lets us automate and version our
infrastructure as code. If you're not familiar with it I recommend [checking out
the website][11]. We'll be using [chef-solo][12], which is easier to use and set
up for a single server. And to simplify it further we'll be using
[knife-solo][13].

### Setting Up

First we'll add knife-solo and librarian-chef to a `Gemfile` and run `bundle` to
install them. The [librarian-chef][14] library helps automate the management of
third-party Chef cookbooks the server depends on.

```ruby
source "https://rubygems.org"

gem "knife-solo"
gem "librarian-chef"
```
{: caption="Creating a `Gemfile` with the necessary dependencies."}

Next we'll initialize a directory structure for Chef with knife:

```sh
$ bundle exec knife solo init .
```
{: caption="Initializing the knife-solo configuration."}

It will generate files and empty directories:

* `.chef/knife.rb` &#8212; The configuration settings for knife.
* `Cheffile` &#8212; External cookbook definitions.
* `cookbooks` &#8212; Directory for vendored cookbooks from the Cheffile.
* `data_bags` &#8212; Directory for data bags. See the [Data Bag
  documentation][15].
* `environments` &#8212; Directory for environment definitions. See [Environment
  documentation][16].
* `nodes` &#8212; Directory for node definitions. See [Nodes documentation][17].
* `roles` &#8212; Directory for role definitions. See [Roles documentation][18].
* `site-cookbooks` &#8212; Directory for your custom Chef cookbooks.

### Adding a Cookbook for a Web Server

Now we're ready to actually start configuring Chef cookbooks. A cookbook
generally defines a single scenario for Chef, such as installing and configuring
a piece of software. Basically "the meat and potatoes" of Chef and probably what
we'll interact with the most. See the [Cookbook documentation][19] if you want
to know more about them.

The primary software needed for running a Jekyll website is a web server that
can serve static files. We'll be using [nginx][20], but Apache or practically
any other server would work.

There are a ton of existing cookbooks we can use, so we'll be using the [nginx
cookbook][21] that is on the cleverly named Chef [Supermarket][22]. It offers
plenty of customization, but we'll start with the easiest solution. To use it
we'll add it to the `Cheffile`:

```ruby
site "http://community.opscode.com/api/v1"

cookbook "nginx"
```
{: caption="Creating a `Cheffile` with a nginx cookbook dependency."}

And then install the cookbook with librarian-chef:

```sh
$ bundle exec librarian-chef install
```
{: caption="Installing the nginx cookbook."}

Now we need to create a node to define which cookbooks will run. The knife-solo
command will automatically look for a node named after the host we run it on, so
we'll name the node `vagrant` and add the default nginx recipe. By default it
installs nginx via a package. We're going to run the latest stable version
available instead, so we'll configure the recipe to compile nginx from the
source. The recipe allows compiling from source simply by setting node
attributes.

```json
{
  "run_list" : [
    "recipe[nginx::default]"
  ],

  "nginx" : {
    "install_method" : "source",

    "source" : {
      "version"  : "1.6.2",
      "checksum" : "b5608c2959d3e7ad09b20fc8f9e5bd4bc87b3bc8ba5936a513c04ed8f1391a18"
    }
  }
}
```
{: caption="Creating `nodes/vagrant.json` with attributes for compiling nginx
from the source."}

Note that I manually determined the `checksum` value by downloading the
compressed file from the official website and using `shasum -a 256 [file]`
locally on OS X.

And we'll add an SSH host for the Vagrant configuration. Vagrant provides the
necessary configuration output by running `vagrant ssh-config --host vagrant`.
Note that the host option can be whatever you would like, but be sure to replace
it in future instructions.

```ssh
Host vagrant
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /Users/Tristan/Sites/jekyll-vps-server/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```
{: caption="Adding a host to `~/.ssh/config` for the Vagrant server."}

Now we can run Chef on the Vagrant server to install nginx. Using the
"bootstrap" command runs the "prepare" and "cook" commands, which installs Chef
on the host then uploads and runs the kitchen, which is all the Chef
configuration. In the future we only need to run the "cook" command.

```sh
$ bundle exec knife solo bootstrap vagrant
```
{: caption="Bootstrapping the Vagrant server with Chef."}

Vagrant should now be running an `nginx` server, but there's no way to access it
outside of the virtual machine yet. Vagrant can forward ports, so we'll forward
port `80` on the Vagrant server to `8080` locally to make it easier to access.

```ruby
Vagrant.configure("2") do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "hashicorp/precise64"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  config.vm.provider "virtualbox" do |box|
    box.memory = 512
  end
end
```
{: lines="1 5-8 15" caption="Forwarding a port in the `Vagrantfile` for nginx."}

After running `vagrant reload` we'll be able to access it locally at
[http://localhost:8080](http://localhost:8080). It will be a "404 Not Found"
error for now though, since we haven't configured a website yet.

### Creating a User

Before we add a website we're going to create a `deploy` user, since deploying
as root isn't the best idea. There are some existing cookbooks we could use, but
Chef already provides basic user management. Since we don't need anything beyond
a user with our public key we'll keep it simple.

First we need to define our cookbook name.

```ruby
name "user"
```
{: caption="Adding the required attribute in the
`site-cookbooks/user/metadata.rb` file."}

Then we can create the simple, default recipe. First we create the user with a
configurable name, setting the home directory path and allowing Chef to manage
the home directory. Then we create the `.ssh` directory and add the
`authorized_keys` file to it, using a template that will contain our public key.

```ruby
user node[:user] do
  home    "/home/#{node[:user]}"
  supports manage_home: true
end

directory "/home/#{node[:user]}/.ssh" do
  mode  "0700"
  owner node[:user]
end

template "/home/#{node[:user]}/.ssh/authorized_keys" do
  mode   "0600"
  owner  node[:user]
  source "authorized_keys"
end
```
{: caption="Creating the default recipe in the
`site-cookbooks/user/recipes/default.rb` file."}

After we can create the required template with our public key.

```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB+wDO2LDfv/dgoerOQYw7C44Gf39lqLGYK9xGfHm1m8V7vZKTz4kG4BxEapT2YbHz/JFaVvU9A6dscdpLiIwdEoWaaM/uMt8XBbdu6UwmSfhIrVs8BWo+wFHxixmy2GxOnUkEf8ATmX0K9VXzgB+5PL6aXsu2zOZlEnkujZG00j9GGohyFApwxJFVRMrShDtDG0R74AT2DdnuqvCIYsn6rGG8MJTWYQpQBrrI5MBP/358QzVX7f1LHmj4RdQZMB3ji9K7YUyYNx49NO3Q6TH3amodY7noxFTXbNbONt6nXVTJN6vxHqnh7YOf3hyjP/pmzjM4o5z/A15c4qA1sNNNwhHOgnlI3uxOMWv+Q0kz7o6hM5pwxy4JBJRqzOqv50xCyL4aMsoKc0enbblOgrSfclSf4g1v0Fro8pkUU6tBcZ5SzEXmg56jSN+YYn2YVQB7029CruxDlZsMcBTByahd1K0ZQUnFrvxCaqgIFrDBZG+TAL5PxvBu1L/+ZMpVlfd25vbpIoZW9J4QJXzWsWPy/IFCAtweIMRiBCUv+kumkTm6/gV2I2nuwCpn3gMG9u+Zjkgifz8MNG+R2aE/o8yneMs2ubL0O+3dkP39CznlX8tVF7Ut0VYK6tQH9KtKArCIedtZvmf5TQ2rDHnAfbLDSR0oAtWdECZwxg/c9Q==
```
{: caption="Adding our public key to the
`site-cookbooks/user/templates/default/authorized_keys` template."}

And finally we need to add the recipe to our node and define the user name.
Since the main purpose for the user is deploying we'll name it `deploy`.

```json
{
  "run_list" : [
    "recipe[user]",
    "recipe[nginx::default]"
  ],

  "nginx" : {
    "install_method" : "source",

    "source" : {
      "version"  : "1.6.2",
      "checksum" : "b5608c2959d3e7ad09b20fc8f9e5bd4bc87b3bc8ba5936a513c04ed8f1391a18"
    }
  },

  "user" : "deploy"
}
```
{: lines="16" caption="Updating the `nodes/vagrant.json` file to use the
cookbook and define the user name."}

Then we can cook the server and ensure we can SSH in as the new user.

```sh
$ bundle exec knife solo cook vagrant
$ ssh deploy@vagrant
```
{: caption="Cooking the Vagrant server and verifying the user creation."}

### Adding a Website

The web server is still pretty useless without a website. We're going to create
a custom cookbook that depends on the nginx cookbook, but also adds and enables
a website.

We'll create a new cookbook with only a name for now and depend on the existing
cookbook we're using.

```ruby
name    "server"
depends "nginx"
```
{: caption="Depending on the nginx recipe in the
`site-cookbooks/server/metadata.rb` file."}

Now we can create the default recipe. Most importantly we need to include the
`nginx` recipe. Since we're going to deploy to `/var/www`, we'll create that
directory and ensure our `deploy` user owns it. We'll use a template for
creating the site and also ensure ownership. And all that's left is to enable it
with `nginx_site`, which comes from the third-party nginx cookbook.

```ruby
include_recipe "nginx::default"

directory "/var/www" do
  owner node[:user]
end

template "example" do
  path   "#{node[:nginx][:dir]}/sites-available/example"
  owner  node[:user]
  source "example.nginx"

  notifies :reload, "service[nginx]"
end

nginx_site "example" do
  enable true
end
```
{: caption="Creating and configuring a site in the
`site-cookbooks/server/recipes/default.rb` file."}

All that's left is to create template file. We'll exclude any customizations for
now, such as compressing and caching assets. Note that we'll be using the
standard [Capistrano][23] directory, `current`, along with the standard Jekyll
compilation directory, `_site`.

```nginx
server {
  root /var/www/example.com/current/_site;
}
```
{: caption="Creating a simple template at
`site-cookbooks/server/templates/default/example.nginx` for the site."}

Now we add the recipe to run list for the node and while we're here we'll also
add a setting to disable the default site.

```json
{
  "run_list" : [
    "recipe[user]",
    "recipe[server]"
  ],

  "nginx" : {
    "install_method" : "source",

    "source" : {
      "version"  : "1.6.2",
      "checksum" : "b5608c2959d3e7ad09b20fc8f9e5bd4bc87b3bc8ba5936a513c04ed8f1391a18"
    },

    "default_site_enabled" : false
  },

  "user" : "deploy"
}
```
{: lines="2-5 15" caption="Updating the `nodes/vagrant.json` file to use the
custom cookbook."}

Now we can cook the server to run the custom recipe.

```sh
$ bundle exec knife solo cook vagrant
```
{: caption="Cooking the Vagrant server with the custom recipe."}

### Installing Ruby

We're going to build the site on the server rather than building it locally so
we need to install and configure Ruby. We'll make our own `ruby` cookbook that
will depend on the `rbenv` cookbook to build Ruby.

```ruby
site "http://community.opscode.com/api/v1"

cookbook "nginx"
cookbook "rbenv"
```
{: caption="Adding the rbenv cookbok dependency the `Cheffile`."}

And we of course need to install the cookbook.

```sh
$ bundle exec librarian-chef install
```
{: caption="Installing the rbenv cookbook."}

Now we can start creating our custom cookbook, which will just depend on the
`rbenv` cookbook.

```ruby
name    "ruby"
depends "rbenv"
```
{: caption="Depending on the rbenv recipe in the
`site-cookbooks/ruby/metadata.rb` file."}

The `rbenv` cookbook provides several recipes. We'll be using the default
recipe, to install `rbenv`, and the `ruby_build` recipe, to install the
dependency for compiling and installing Ruby. And we'll install a configurable
version globally, as well as install the `bundler` dependency.

```ruby
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

rbenv_ruby node[:ruby][:version] do
  global true
end

rbenv_gem "bundler" do
  ruby_version node[:ruby][:version]
end
```
{: caption="Creating the recipe in the `site-cookbooks/ruby/recipes/default.rb`
file."}

Now we can add the recipe in our run list and configure the version of Ruby we
want to install.

```json
{
  "run_list" : [
    "recipe[user]",
    "recipe[ruby]",
    "recipe[server]"
  ],

  "nginx" : {
    "install_method" : "source",

    "source" : {
      "version"  : "1.6.2",
      "checksum" : "b5608c2959d3e7ad09b20fc8f9e5bd4bc87b3bc8ba5936a513c04ed8f1391a18"
    },

    "default_site_enabled" : false
  },

  "ruby" : {
    "version" : "2.1.5"
  },

  "user" : "deploy"
}
```
{: lines="4 19-21" caption="Adding attributes to `nodes/vagrant.json` for the
Ruby recipe and version."}

Now we can cook the server and ensure it's installed. Note that compiling Ruby
will take a few minutes.

```sh
$ bundle exec knife solo cook vagrant
$ ssh vagrant -C "/opt/rbenv/shims/ruby -v"
ruby 2.1.5p273 (2014-11-13 revision 48405) [x86_64-linux]
```
{: caption="Cooking the Vagrant server and verifying the Ruby installation."}

## Summary

We now how the minimal components needed to deploy a Jekyll website to a Vagrant
box. See the [jekyll-vps-server][24] contains the complete source, with the
[part-1 branch][25] being specific to this article.

There's still plenty to be done. In the [next part][26] we'll set up Capistrano,
including deployment of local changes. And in the following part we'll prepare
and deploy a production version. [E-mail me](mailto:hello@tristandunn.com) if
you have any tips, comments, or questions.

[1]: https://jekyllrb.com
[2]: https://pages.github.com
[3]: https://www.digitalocean.com
[4]: https://www.chef.io
[5]: https://www.vagrantup.com
[6]: https://www.vagrantup.com/downloads.html
[7]: https://www.virtualbox.org/wiki/Downloads
[8]: https://www.vagrantup.com/docs/providers
[9]: https://www.vagrantup.com/docs/vagrantfile
[10]: https://www.vagrantbox.es
[11]: https://www.chef.io/products/chef-infra
[12]: https://docs.chef.io/chef_solo/
[13]: https://matschaffer.github.io/knife-solo/
[14]: https://github.com/applicationsonline/librarian-chef
[15]: https://docs.chef.io/data_bags/
[16]: https://docs.chef.io/environments/
[17]: https://docs.chef.io/nodes/
[18]: https://docs.chef.io/roles/
[19]: https://docs.chef.io/cookbooks/
[20]: https://nginx.org
[21]: https://supermarket.getchef.com/cookbooks/nginx
[22]: https://supermarket.getchef.com
[23]: https://capistranorb.com
[24]: https://github.com/tristandunn/jekyll-vps-server
[25]: https://github.com/tristandunn/jekyll-vps-server/compare/part-0...part-1
[26]: /2015/05/05/deploying-jekyll-to-vps-part-2/

*[VPS]: Virtual Private Server
