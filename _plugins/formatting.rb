module Jekyll
  module Filters
    module Formatting
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
end

Liquid::Template.register_filter(Jekyll::Filters::Formatting)
