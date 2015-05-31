server "tristandunn", user: "deploy", roles: %w(web)

set :branch,        ENV["BRANCH"] || "master"
set :configuration, "_config.yml,_config_production.yml"
