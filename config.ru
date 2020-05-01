# frozen_string_literal: true

require "rack/static"

use Rack::Static, urls: [""], root: "_site", index: "index.html"

run lambda { |_env|
  [
    200,
    {
      "Content-Type"  => "text/html",
      "Cache-Control" => "public, max-age=86400"
    },
    File.open("_site/index.html", File::RDONLY)
  ]
}
