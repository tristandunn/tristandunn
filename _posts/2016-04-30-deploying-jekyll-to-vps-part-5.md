---
part: 5
title: "Deploying Jekyll to a VPS"
image: "posts/2016-04-30/image@2x.png"
footer: "series/deploying-jekyll-to-vps.html"
category: chef
subtitle: "Part 5: Switching to HTTPS Only"
description: "Switch the server to only respond to HTTPS requests, with support for the SPDY protocol."
redirect_from: /2016/04/30/deploying-jekyll-to-vps-part-5/
---

While a secure connection may not seem relevant for a static website, it affects
search engine rankings now that [Google uses HTTPS as a ranking signal.][1] And
apart from purchasing a certificate or generating a free certificate from [Let's
Encrypt][2], it's not that difficult to support.

## Vagrant Certificate

To start, let's generate a self-signed certificate on the Vagrant server to
allow us to test the configuration changes. We can do so by SSHing into the
Vagrant server and running the following commands. Note that it can take some
time to generate the `dhparam` file.

```sh
$ cd /etc/ssl
$ sudo openssl genrsa -out example.com.key 2048
$ sudo openssl req -new -x509 -key example.com.key -out example.com.crt -days 3650 -subj /CN=example.local

$ cd /etc/ssl/certs
$ sudo openssl dhparam -out dhparam.pem 4096
```
{: caption="Generate a self-signed certificate on the Vagrant server."}

On OS X we need to trust the generated certificate. To do so copy the
`example.com.crt` file out of the Vagrant server and drag it into the "Keychain
Access" program. After it's added, double click it, expand the "Trust" section,
and set the "When using this certificate" option to "Always Trust".

Also, since we generated the certificate for `example.local` we need to add it
to our local hosts file. To add a host on OS X, add `127.0.0.1 example.local` on
a blank line to the `/etc/hosts` file. Note that we need to use `sudo` to write
to it.

## Server Configuration

Now we need to ensure nginx compiles with the SSL and SPDY modules, creates a
new file for the SSL configuration, and uses the new configuration file when a
certificate is present.

### SSL and SPDY Modules

To compile with SSL and SPDY we add the modules to the node configuration. We
also ensure the gzip static module is still available.

```json
{
  "nginx" : {
    "install_method" : "source",

    "source" : {
      "version"  : "1.6.2",
      "checksum" : "b5608c2959d3e7ad09b20fc8f9e5bd4bc87b3bc8ba5936a513c04ed8f1391a18",
      "modules"  : [
        "nginx::http_gzip_static_module",
        "nginx::http_spdy_module",
        "nginx::http_ssl_module"
      ]
    },

    "default_site_enabled" : false
  }
}
```
{: lines="8-12" caption="Customize the modules in the JSON for nodes."}

Now we can run `bundle exec knife solo cook vagrant` to recompile nginx with the
modules.

### SSL Configuration

Next we need to add a lot of configuration to use and configure the SSL and SPDY
modules. We're going to create it in a separate `example.ssl.nginx` file to only
enforce HTTPS when a certificate is present.

To learn more about what each directive does, check out the [documentation for
ngx_http_ssl_module][3]. We could also generate this with the [configuration
generator from Mozilla][4], which also supports generation for other servers.

```nginx
# Redirect HTTP requests to the HTTPS endpoint.
server {
  listen 80;
  server_name example.local;

  return 301 https://$server_name$request_uri;
}

server {
  root /var/www/example.com/current/_site;

  # Listen on the standard SSL port, with SPDY enabled.
  listen 443 ssl spdy;
  server_name example.local;

  # Enable SSL.
  ssl on;

  # Set the paths for the certificate files.
  ssl_dhparam /etc/ssl/certs/dhparam.pem;
  ssl_certificate /etc/ssl/example.com.crt;
  ssl_certificate_key /etc/ssl/example.com.key;

  # Cache connection information.
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 24h;
  ssl_session_tickets off;

  # The ciphers and protocols supported.
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA:!CAMELLIA;
  ssl_prefer_server_ciphers on;

  # Enable OCSP stapling.
  ssl_stapling on;
  ssl_stapling_verify on;

  # Use the Google DNS servers for name resolution.
  resolver 8.8.8.8 8.8.4.4 valid=300s;
  resolver_timeout 10s;

  # Enable compression and customize the timeout for SPDY.
  spdy_headers_comp 5;
  spdy_keepalive_timeout 300;

  # Add headers to enable HSTS and SPDY.
  add_header Alternate-Protocol 443:npn-spdy/3;
  add_header Strict-Transport-Security max-age=63072000;

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
{: caption="Create an SSL template at
`site-cookbooks/server/templates/default/example.ssl.nginx`."}

We can add a small condition to our default server recipe to use the new SSL
configuration when the certificate is present.

```ruby
include_recipe "nginx::default"

directory "/var/www" do
  owner node[:user]
end

template "example" do
  path  "#{node[:nginx][:dir]}/sites-available/example"
  owner node[:user]

  # Use an SSL configuration file when the certificate is present.
  if File.exist?("/etc/ssl/example.com.crt")
    source "example.ssl.nginx"
  else
    source "example.nginx"
  end

  notifies :reload, "service[nginx]"
end

nginx_site "example" do
  enable true
end
```
{: lines="11-16" caption="Update the Ruby default recipe to conditionally enable
the SSL configuration."}

We can run `bundle exec knife solo cook` to update the configuration, but note
that this will break access to the server until we update Vagrant to handle the
new SSL port.

### Vagrant Port Forwarding

Next we need update the Vagrant port forwarding. And since it's kind of annoying
having to request `http://example.local:8080` or `https://example.local:4443`
we're also going to improve the handling to better match the production version.
First we need to install the `vagrant-triggers` plug-in to allow us to run
commands for any Vagrant events.

```sh
# If you're using Homebrew you'll probably need this variable.
$ export NOKOGIRI_USE_SYSTEM_LIBRARIES=1

$ vagrant plugin install vagrant-triggers
```
{: caption="Install the `vagrant-triggers` plug-in."}

Now we can run arbitrary commands when starting or stopping the Vagrant
instance, so we'll use `pfctl` to map the ports to the standard `80` and `443`
ports. We're also adding a new forwarded port for HTTPS.

```ruby
Vagrant.configure(2) do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "hashicorp/precise64"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine.
  config.vm.network "forwarded_port", guest: 443, host: 4443
  config.vm.network "forwarded_port", guest: 80,  host: 8080

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  config.vm.provider "virtualbox" do |box|
    box.memory = 512
  end

  # Add rules when provisioning, starting, or reloading the server to forward
  # the standard HTTP and HTTPS ports to the Vagrant forwarded ports.
  config.trigger.after [:provision, :up, :reload] do
    system <<-EOC
      echo "
        rdr pass on lo0 inet proto tcp from any to 127.0.0.1 port 80 -> 127.0.0.1 port 8080
        rdr pass on lo0 inet proto tcp from any to 127.0.0.1 port 443 -> 127.0.0.1 port 4443
      " | sudo pfctl -ef - > /dev/null 2>&1;
      echo "==> Fowarding Ports: 80 -> 8080, 443 -> 4443"
    EOC
  end

  # Remove the port forwarding rules when halting or destroying the server.
  config.trigger.after [:halt, :destroy] do
    system <<-EOC
      sudo pfctl -df /etc/pf.conf > /dev/null 2>&1;
      echo "==> Removing Port Forwarding"
    EOC
  end
end
```
{: lines="8 17-35" caption="Add triggers to forward ports `80` and `443`
locally."}

Note that we'll have to enter our password now, since we need `sudo` to run the
commands. After running `vagrant reload` to forward the ports we can access the
website at <https://example.local>. And if we try to access it over HTTP at
<http://example.local> it will redirect us to HTTPS.

## Remote Certificate

For production we need a trusted certificate rather than a self-signed version.
As mentioned before we can use [Let's Encrypt][2], but for now we'll stick with
[DNSimple][5] from before.

### Buy a Certificate

After signing into DNSimple, navigate to the domain we're going to buy a
certificate for. In the SSL certificates section click on "Buy a new SSL
Certificate". Choose the appropriate subdomain for the "Host Name", which is
`www` if we're [securing the root domain][6] such as our `example.com`.

Creating the certificate will take a bit of time, but we'll receive a few
e-mails when it's completed. We can also check the status on the DNSimple
certificate page.

And while that's running, let's generate the `dhparam` on the production server.

```sh
$ cd /etc/ssl/certs
$ sudo openssl dhparam -out dhparam.pem 4096
```
{: caption="Increase the key size for the Diffie Hellman key exchange."}

### Install the Certificate

Once DNSimple knows the certificate is available it will provide the certificate
bundle and private key. We can find the download links for them under the nginx
section of the "Install the SSL Certificate" page linked from the certificate
page.

The `www_example_com.pem` file is our certificate, which we'll store at
`/etc/ssl/example.com.crt`. And the `www_example_com.key` file is our
certificate key, which we'll store at `/etc/ssl/example.com.key`. Now if
everything is correct when we run `bundle exec knife solo cook example` it will
use the new SSL configuration.

## Summary

We now have an HTTPS only website, which will help with our SEO and ensure any
access is secure. See the [jekyll-vps-server][7] repository for the complete
Chef source code, with the [part-5 branch][8] being specific to this article.

One final item to remember is to use HTTPS for external resources, such as forms
and external CSS or JavaScript. Also update any hardcoded URLs, such as the
asset domain or base URL in Jekyll.

[E-mail me](mailto:hello@tristandunn.com) if you have any tips, comments, or
questions.




[1]: https://webmasters.googleblog.com/2014/08/https-as-ranking-signal.html
[2]: https://letsencrypt.org
[3]: https://nginx.org/en/docs/http/ngx_http_ssl_module.html
[4]: https://mozilla.github.io/server-side-tls/ssl-config-generator/
[5]: https://dnsimple.com/r/3edceb992aa254
[6]: https://support.dnsimple.com/articles/ssl-certificate-hostname/#securing-the-root-domain
[7]: https://github.com/tristandunn/jekyll-vps-server
[8]: https://github.com/tristandunn/jekyll-vps-server/compare/part-4...part-5
