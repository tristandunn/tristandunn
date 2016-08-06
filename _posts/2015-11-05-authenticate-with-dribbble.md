---
title: "Authenticate with the Dribbble API"
image: "posts/2015-11-05/image@2x.png"
category: ruby
description: "A complete example for authenticating a user with the Dribbble API using Ruby on Rails."
---

The [Dribbble API][1] supports user authentication with [OAuth 2.0][2], allowing
applications to comment, like, and more as the authenticated user. We can also
use it to verify a user, which is what we're going to do.

Why would you want to verify a user? Maybe you're selling a product that
requires the user to be a <q>player</q> on Dribbble. Or you want to use Dribbble
as the authentication for your application. Basically any circumstance where you
want to know it's a specific person, possibly with a specific status.

## Creating an Application

We need an application to use when authenticating a user. The application
provides a client ID and secret for us to use, as well as provides information
to the user about the application.

If you don't already have one, [create an application][3] on Dribbble. Enter a
name, description, and website URL which help users identify the application.
The callback URL is where Dribbble will redirect the user after an authorization
attempt, which we use to complete the authentication or handle any errors. For
this example we're going to use `http://localhost:3000/sessions/new`, which
refers to the <q>new</q> action for a <q>sessions</q> controller in our local
Rails application.

## Preparing Rails

Next we need to create and set up our Rails application. We'll just generate an
application by running `rails new dribbble-example`. There are also a couple of
dependencies to add and configuration that we should perform to help ease the
authentication process.

### Dependencies

We'll add two dependencies to the `Gemfile`. The [oauth2][4] dependency is the
OAuth 2.0 client we'll be using for authentication. And the [dotenv-rails][5]
dependency that allows us to set environment variables for the client ID and
secret, instead of hard coding them into the Rails application.

<figure>
{% highlight ruby %}
gem "oauth2"

group :development do
  gem "dotenv-rails"
end
{% endhighlight %}
  <figcaption>Adding the dependencies to the <code>Gemfile</code>.</figcaption>
</figure>

Don't forget to run `bundle` to install them.

### Configuration

To configure the environment variables we'll create a `.env` file in the root
directory of the Rails application. Your client ID and secret on your
application page, which is available under [your applications][6] on Dribbble.

<figure>
{% highlight bash %}
DRIBBBLE_CLIENT_ID="aa47c7086a79cbd534bc677159f9e813a63ddc1c1e2f3fbf04fdf8d616cda375"
DRIBBBLE_CLIENT_SECRET="467652ff939bc8b39020e393453f79eb5efb7b550089d49ee487b62be4d82db8"
{% endhighlight %}
  <figcaption>Adding the client ID and secret to the <code>.env</code> file.</figcaption>
</figure>

There's no harm in exposing the client ID, but the secret should not be public.
It's recommended to ignore the `.env` file in the `.gitignore` file, otherwise
it's no better than hard coding the values.

## Authenticating

Our application is going to be simple. A homepage with a "Connect with Dribbble"
link when unauthenticated, an action for creating a token, and an alternative
homepage displaying the user's name when authenticated.

### Authorization

When a user is not authenticated we need to link to Dribbble to start the OAuth
process, so we'll start by creating a `Token` class for generation the
authorization URL. It's a decent amount of code to start with, but it's
predominately configuration options. Note that we're requesting the default
`public` scope, but you can [choose from others][7] depending on your needs.

<figure>
{% highlight ruby %}
class Token
  # Settings for the OAuth client.
  CLIENT_ID      = ENV["DRIBBBLE_CLIENT_ID"].freeze
  CLIENT_SCOPE   = "public".freeze
  CLIENT_SECRET  = ENV["DRIBBBLE_CLIENT_SECRET"].freeze
  CLIENT_OPTIONS = {
    site:          "https://api.dribbble.com".freeze,
    token_url:     "https://dribbble.com/oauth/token".freeze,
    authorize_url: "https://dribbble.com/oauth/authorize".freeze
  }.freeze

  # Generate an authorization URL with our client settings.
  def self.authorize_url
    client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, CLIENT_OPTIONS)
    client.auth_code.authorize_url(scope: CLIENT_SCOPE)
  end
end
{% endhighlight %}
  <figcaption>The initial <code>app/models/token.rb</code> file.</figcaption>
</figure>

We need a page for displaying the authorization link now, so let's add a simple
<q>Pages</q> controller.

<figure>
{% highlight ruby %}
class PagesController < ApplicationController
  def index
  end
end
{% endhighlight %}
  <figcaption>A minimal <code>app/controllers/pages_controller.rb</code> file.</figcaption>
</figure>

And we of course need to set up a route for it, which we'll just have it be the
root.

<figure>
{% highlight ruby %}
Rails.application.routes.draw do
  root to: "pages#index"
end
{% endhighlight %}
  <figcaption>Adding a root route to the <code>config/routes.rb</code> file.</figcaption>
</figure>

Lastly we need a view to display the link.

<figure>
{% highlight erb %}
<%= link_to "Connect with Dribbble", Token.authorize_url %>
{% endhighlight %}
  <figcaption>Super minimal <code>app/views/pages/index.html.erb</code> file.</figcaption>
</figure>

### Creating a Token

After a user authorizes our application then Dribbble will redirect them to our
callback URL with a code. We can use the code provided to request an access
token, which allows us to perform API requests on behalf of the user.

To start we'll add a `create_from_code` method to our `Token` class. We will
also extract the client creation to a separate method for reuse.

<figure>
{% highlight ruby %}
class Token
  # Settings for the OAuth client.
  CLIENT_ID      = ENV["DRIBBBLE_CLIENT_ID"].freeze
  CLIENT_SCOPE   = "public".freeze
  CLIENT_SECRET  = ENV["DRIBBBLE_CLIENT_SECRET"].freeze
  CLIENT_OPTIONS = {
    site:          "https://api.dribbble.com".freeze,
    token_url:     "https://dribbble.com/oauth/token".freeze,
    authorize_url: "https://dribbble.com/oauth/authorize".freeze
  }.freeze

  # Create an OAuth client with our settings.
  def self.client
    OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, CLIENT_OPTIONS)
  end

  # Create a token with our client using the code provided.
  def self.create_from_code(code)
    client.auth_code.get_token(code).token
  end

  # Generate an authorization URL with our client.
  def self.authorize_url
    client.auth_code.authorize_url(scope: CLIENT_SCOPE)
  end
end
{% endhighlight %}
  <figcaption>Adding a <code>create_from_code</code> method to the <code>app/models/token.rb</code> file.</figcaption>
</figure>

Next we can create our `SessionsController` and use the new method for creating
an access token that we'll store in the user's session.

<figure>
{% highlight ruby %}
class SessionsController < ApplicationController
  def new
    # Create an access token from the provided code.
    session[:token] = Token.create_from_code(params[:code])

    # Redirect back to the homepage.
    redirect_to root_path
  end
end
{% endhighlight %}
  <figcaption>Creating the <code>app/controllers/sessions_controller.rb</code> file.</figcaption>
</figure>

Now we can add a route for the new action. Remember that this is the action that
Dribbble redirects to, so make sure it matches in your application settings if
you're using a different name.

<figure>
{% highlight ruby %}
Rails.application.routes.draw do
  resources :sessions, only: [:new]

  root to: "pages#index"
end
{% endhighlight %}
  <figcaption>Adding sessions route to the <code>config/routes.rb</code> file.</figcaption>
</figure>

### Using the Token

We can now use the access token to make API requests on behalf of the user.
Let's make a basic `User` class that fetches the attributes for the authorized
user, which we'll use to display a message to them.

<figure>
{% highlight ruby %}
class User
  # Create an OAuth2::AccessToken from the provided access token and our client.
  def initialize(access_token)
    @token = OAuth2::AccessToken.from_hash(Token.client, access_token: access_token)
  end

  # Fetch the user's attributes as parsed JSON with indifferent access and
  # memoize.
  def attributes
    @attributes ||= @token.get("/v1/user").parsed.with_indifferent_access
  end
end
{% endhighlight %}
  <figcaption>Creating the <code>app/models/user.rb</code> file.</figcaption>
</figure>

We'll create a user in our root controller when a token is present.

<figure>
{% highlight ruby %}
class PagesController < ApplicationController
  def index
    if session[:token].present?
      @user = User.new(session[:token])
    end
  end
end
{% endhighlight %}
  <figcaption>Adding user creation to the <code>app/controllers/pages_controller.rb</code> file.</figcaption>
</figure>

Which we can conditionally use in the view to greet the user.

<figure>
{% highlight erb %}
<% if @user.present? %>
  Welcome, <%= @user.attributes[:name] %>!
<% else %>
  <%= link_to "Connect with Dribbble", Token.authorize_url %>
<% end %>
{% endhighlight %}
  <figcaption>Conditional <code>app/views/pages/index.html.erb</code> file.</figcaption>
</figure>

## Summary

While the resulting application is rather basic it gives you an idea how to
integrate the Dribbble API into a new or existing application. Check out [the
official documentation][8] for what you can do with an authenticated user.

Also, in a real application there are changes or additions you may want to make.
If you need to make requests in a background job, you'll probably want to store
the access token in the database. If you're displaying user information from the
API, as we are here, you'll want to cache it to avoid making an API request for
every user request. Error handling would also be a welcomed addition. And a
reminder that if you want more than read-only access you'll need to request
[other scopes][7].

See the [dribbble-example][9] repository for the complete source code to the
application. Now on to the hard part, the idea. [E-mail
me](mailto:hello@tristandunn.com) if you make an application, or if you have any
comments or questions.





[1]: http://developer.dribbble.com
[2]: http://oauth.net/2/
[3]: https://dribbble.com/account/applications/new
[4]: https://github.com/intridea/oauth2
[5]: https://github.com/bkeepers/dotenv
[6]: https://dribbble.com/account/applications
[7]: http://developer.dribbble.com/v1/oauth/#scopes
[8]: http://developer.dribbble.com/v1/
[9]: https://github.com/tristandunn/dribbble-example
