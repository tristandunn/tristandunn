require "./config/deploy/local/file_strategy"

server "vagrant", user: "deploy", roles: %w(web)

set :git_strategy, FileStrategy
