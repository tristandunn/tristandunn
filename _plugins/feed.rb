module Jekyll
  module Filters
    module Feed
      def last_updated(posts)
        Array(posts).map do |post|
          created_at  = post.is_a?(Hash) ? post["date"] : post.date
          modified_at = post["modified_at"]

          time(modified_at || created_at)
        end.max
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Filters::Feed)
