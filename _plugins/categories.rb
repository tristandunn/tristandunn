module Jekyll
  class CategoryIndex < Page
    def initialize(site, base, directory, payload)
      @site = site
      @base = base
      @dir  = directory
      @name = "index.html"

      process(@name)
      read_yaml(File.join(base, "_layouts"), "category.html")

      data["title"]    = ["Category:", payload["name"].titleize].join(" ")
      data["category"] = payload
    end
  end

  class GenerateCategories < Generator
    safe     true
    priority :low

    def generate(site)
      site.categories.each do |name, posts|
        data      = { "name" => name, "posts" => posts }
        directory = File.join("categories", name)

        index = CategoryIndex.new(site, site.source, directory, data)
        index.render(site.layouts, site.site_payload)
        index.write(site.dest)

        site.pages << index
      end
    end
  end
end
