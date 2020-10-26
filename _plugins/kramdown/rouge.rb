# frozen_string_literal: true

require "kramdown/converter/syntax_highlighter/rouge"

module Kramdown
  module Converter
    module SyntaxHighlighter
      module Rouge
        # Highlight code.
        #
        # @param converter [Kramdown::Converter] The document converter.
        # @param code [String] The code to highlight.
        # @param language [String] The language to highlight the code as.
        # @param type [Symbol] The type of element block. (+:span+ or +:block+)
        # @param call_options [Hash] The options to call with.
        # @return [String] The highlighted code.
        def self.call(converter, code, language, type, call_options)
          lexer   = ::Rouge::Lexer.find_fancy(language, code)
          options = options(converter, type)

          # Merge the inline Kramdown attributes into the lexer options.
          options = options.merge(call_options[:ial] || {})

          # Set the language in the lexer options.
          options[:language] = language

          formatter = formatter_class(options).new(options)
          formatter.format(lexer.lex(code))
        end
      end
    end
  end
end
