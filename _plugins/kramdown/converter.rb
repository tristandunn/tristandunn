# frozen_string_literal: true

require "kramdown/converter/html"

module Kramdown
  module Converter
    class Html
      WIDOW_MATCHER   = /(.*)\s(.*)\z/m
      WIDOW_SEPARATOR = "&#160;"

      # Convert a code block to HTML with highlighted code.
      #
      # @param element [Kramdown::Element] The element to convert.
      # @return [String] The code block with highlighted code.
      def convert_codeblock(element, _indent)
        highlight_code(
          element.value,
          extract_code_language!(element.attr),
          :block,
          element.options
        )
      end

      # Convert a code span to HTML.
      #
      # @param element [Kramdown::Element] The element to convert.
      # @return [String] The code span.
      def convert_codespan(element, _indent)
        format_as_span_html("code", element.attr, escape_html(element.value))
      end

      # Convert text to an HTML escaped version with a separator to
      # prevent widows.
      #
      # @param element [Kramdown::Element] The element to convert.
      # @return [String] The HTML escaped text.
      def convert_text(element, _indent)
        html = escape_html(element.value, :text)
               .tr("\n", " ")

        # Ignore any HTML without spaces.
        return html unless html.include?(" ")

        # If the text ends with a space then there's more text coming up and no
        # need to insert the separator.
        return html if html.end_with?(" ")

        html
          .split(WIDOW_MATCHER)  # Split on the last space.
          .slice(1..-1)          # Remove the global match.
          .join(WIDOW_SEPARATOR) # Join with the separator.
      end
    end
  end
end
