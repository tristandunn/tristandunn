# frozen_string_literal: true

module Jekyll
  module Filters
    module Formatting
      NON_BREAKING_SPACE = "&#160;"

      # Convert a date to a string with +strftime+.
      #
      # @param [Date] date The date to convert.
      # @param [String] format The +strftime+ format.
      # @return [String] The formatted dated.
      def date_to_string(date, format = "%B %o, %Y")
        date   = time(date)
        format = format.sub("%o", date.day.ordinalize)

        date.strftime(format)
      end

      # Titleize a string.
      #
      # @param [String] string The string to titleize.
      # @return [String] The titleize string.
      def titleize(string)
        string.titleize
      end

      # Replace the last space with a non-breaking-space.
      #
      # @param [String] string The string to modify.
      # @return [String] The widowless string.
      def widow(string)
        string.gsub(/(.*)(\s)(.*)/, "\\1#{NON_BREAKING_SPACE}\\3")
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Filters::Formatting)
