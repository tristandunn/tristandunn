# frozen_string_literal: true

module Jekyll
  module Filters
    module Feed
      # Determine the time for the most recently updated post.
      #
      # @param [Array] posts The posts to check.
      # @return [DateTime]
      def last_updated(posts)
        Array(posts).map { |post| time(post["modified_at"] || post.date) }.max
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Filters::Feed)
