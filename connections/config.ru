run lambda { |env|
  [
    200,
    {
      "cache-control" => "public, max-age=86400",
      "content-type"  => "text/html"
    },
    File.open("index.html", File::RDONLY)
  ]
}
