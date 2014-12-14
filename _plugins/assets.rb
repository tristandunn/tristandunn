require "jekyll-assets"
require "jekyll-assets/bourbon"

module Jekyll
  module AssetsPlugin
    class Renderer
      def render_image_with_attributes
        normal = site.assets[path]
        retina = site.assets[path.sub(/\.\w+$/, "@2x\\0")]
        srcset = [[AssetPath.new(normal).to_s, "1x"].join(" "),
                  [AssetPath.new(retina).to_s, "2x"].join(" ")
                 ].join(", ")

        @attrs << %{ srcset="#{srcset}"}

        render_image_without_attributes
      end

      alias_method :render_image_without_attributes, :render_image
      alias_method :render_image, :render_image_with_attributes
    end
  end
end
