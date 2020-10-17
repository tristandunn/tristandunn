# frozen_string_literal: true

rule "MM001", "No multiple spaces" do
  tags    :whitespace
  aliases "no-multiple-spaces"

  check do |document|
    codeblock_lines = document
                      .find_type_elements(:codeblock)
                      .map do |element|
                        line = document.element_linenumber(element)

                        (line..line + element.value.lines.count).to_a
                      end
                      .flatten

    lines = document.matching_lines(/[^\s]+\s{2,}/)
    lines - codeblock_lines
  end
end
