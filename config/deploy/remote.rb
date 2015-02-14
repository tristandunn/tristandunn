server "104.236.111.217", user: "deploy", roles: %w(web)

set :branch,        ENV["BRANCH"] || "master"
set :configuration, "_config.yml,_config_production.yml"
