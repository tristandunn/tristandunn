# frozen_string_literal: true

require "rouge"

module Rouge
  module Formatters
    class CustomHighlighter < HTMLLinewise
      SPACE                 = " "
      BLANK_LINE            = [[Rouge::Token::Tokens::Text, "\n"].freeze].freeze
      CLASS_FORMAT          = "line line-%<line>i"
      HIGHLIGHT_CLASS       = "highlight"
      RANGE_SEPARATOR       = "-"
      PARAGRAPH_MATCHER     = %r{</?p>}
      HIGHLIGHT_LINE_CLASS  = "highlight-line"
      HIGHLIGHT_LINES_CLASS = "highlight-lines"

      attr_reader :formatter, :options

      # Create a new highlighter.
      #
      # @param options [Hash] The options for highlighting.
      # @option options [String] :lines The specific lines to call out.
      # @option options [String] :caption The figure caption.
      def initialize(options = {})
        @options = options.transform_keys(&:to_sym)

        super(Rouge::Formatters::HTML.new, @options)
      end

      # Builds a figure caption if a caption option is present.
      #
      # @return [String|nil]
      def caption
        return if options[:caption].to_s.strip.empty?

        html = Kramdown::Document
               .new(options[:caption])
               .to_html
               .gsub(PARAGRAPH_MATCHER, "")
               .strip

        "<figcaption>#{html}</figcaption>"
      end

      # Builds necessary CSS class names for the container.
      #
      # @return [String]
      def container_class_names
        class_names = [HIGHLIGHT_CLASS]
        class_names << HIGHLIGHT_LINES_CLASS if lines.any?
        class_names.join(SPACE)
      end

      # Builds necessary CSS class names for the next line of code.
      #
      # @param line [Number] The line number the class names are for.
      # @return [String]
      def line_class_names(line)
        class_names = [Kernel.format(CLASS_FORMAT, line: line)]
        class_names << HIGHLIGHT_LINE_CLASS if lines.include?(line)
        class_names.join(SPACE)
      end

      # Convert line numbers and ranges to an array of numbers.
      #
      # @param value [String] The line numbers and ranges to parse.
      # @return [Array]
      def lines
        @lines ||= options.fetch(:lines, nil)
                          .to_s
                          .split(SPACE)
                          .flat_map do |item|
                            item = item.split(RANGE_SEPARATOR, 2)
                            item = Range.new(*item) if item.size == 2
                            item.to_a
                          end
                          .map(&:to_i)
      end

      # Stream the highlighted tokens to the provided block.
      #
      # @param tokens [Array] The tokens to highlight.
      # @return [void]
      def stream(tokens, &block)
        yield stream_header

        token_lines(tokens).with_index(1) do |line, index|
          yield %(<div class="#{line_class_names(index)}">)

          line = BLANK_LINE if line.empty?

          formatter.stream(line, &block)

          yield %(</div>)
        end

        yield stream_footer
      end

      private

      # Return the footer for the highlighter stream.
      #
      # @return [string]
      def stream_footer
        %(</code></pre></div>#{caption}</figure>)
      end

      # Return the header for the highlighter stream.
      #
      # @return [string]
      def stream_header
        %(
          <figure>
            <div class="#{container_class_names}" data-language="#{options[:language]}">
              <pre><code>)
      end
    end
  end
end
