# frozen_string_literal: true

class PurgecssNotFoundError < RuntimeError
end

class PurgecssRuntimeError < RuntimeError
end

Jekyll::Hooks.register(:site, :post_write) do |site|
  raise PurgecssNotFoundError unless File.file?("./node_modules/.bin/purgecss")

  path = [
    site.config.fetch("destination"),
    site.config.fetch("css_dir", "css")
  ].join("/")

  raise PurgecssRuntimeError unless system(
    "./node_modules/.bin/purgecss " \
    "--config ./purgecss.config.js " \
    "--output #{path}/"
  )
end
