lock "3.4.0"

# Application name and deployment location.
set :repo_url,    "git@github.com:tristandunn/tristandunn.com.git"
set :deploy_to,   "/var/www/tristandunn.com"
set :application, "tristandunn"

# Ensure bundler is run for the web role.
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
