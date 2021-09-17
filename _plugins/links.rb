# frozen_string_literal: true

require "nokogiri"

module Jekyll
  module Filters
    module Links
      ATTRIBUTES    = { "rel" => "nofollow noopener noreferrer" }.freeze
      EXCLUDED_URLS = %w(github.com miroha.com tristandunn.com).freeze

      # Filter links to automatically add specific attributes to them.
      #
      # @param [String] format The string to filter links in.
      # @return [String] The string with filtered links.
      def filter_links(string)
        document = Nokogiri::HTML.fragment(string)
        document.css("a").each do |link|
          href = link.get_attribute("href")

          ATTRIBUTES.each do |attribute, value|
            next if attribute.casecmp("ref").zero? ||
                    EXCLUDED_URLS.any? { |url| href.include?(url) }

            link.set_attribute(attribute, value)
          end
        end

        document.to_s
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Filters::Links)
