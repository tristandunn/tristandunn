require "jekyll/assets"

Gem::Specification.find_by_name("bourbon").gem_dir.tap do |path|
  Sprockets.append_path(File.join(path, "app", "assets", "stylesheets"))
end
