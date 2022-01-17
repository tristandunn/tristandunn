# frozen_string_literal: true

require "kramdown/parser/kramdown"

module Kramdown
  module Parser
    class Kramdown
      # Remove the existing fenced code block matchers.
      remove_const(:FENCED_CODEBLOCK_START)
      remove_const(:FENCED_CODEBLOCK_MATCH)

      # Define the new code block matchers to use ``` instead of ~~~.
      FENCED_CODEBLOCK_START = /\A`{3,}/
      FENCED_CODEBLOCK_MATCH = /\A
        ((`){3,})\s*?              # The start of the code block.
        ((\S+?)(?:\?\S*)?)?\s*?\n  # The optional name of the language.
        (.*?)                      # The code.
        ^\1\2*\s*?\n               # The end of the code block.
      /mx

      # Remove the existing parser.
      @@parsers.delete(:codeblock_fenced)

      # Define the parser using the new constant.
      define_parser(:codeblock_fenced, FENCED_CODEBLOCK_START)
    end
  end
end
