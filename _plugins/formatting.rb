require "active_support/core_ext/string/inflections"
require "active_support/core_ext/integer/inflections"

module Jekyll
  module Filters
    NON_BREAKING_SPACE = "&#160;".freeze

    def date_to_string(date, format = "%B %o, %Y")
      date   = time(date)
      format = format.sub("%o", date.day.ordinalize)

      date.strftime(format)
    end

    def titleize(string)
      string.titleize
    end

    def widow(string)
      string.gsub(/(.*)(\s)(.*)/, "\\1#{NON_BREAKING_SPACE}\\3")
    end
  end
end
