module Jekyll
  module Filters
    def last_updated(posts)
      posts = [posts].flatten
      dates = posts.map do |post|
        created_at  = post.is_a?(Hash) ? post["date"] : post.date
        modified_at = post["modified_at"]

        time(modified_at || created_at)
      end

      dates.max
    end
  end
end
